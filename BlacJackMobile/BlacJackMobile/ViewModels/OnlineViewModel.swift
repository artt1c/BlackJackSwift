import SharedModels
import SwiftUI

/// Manages a WebSocket connection to the Blackjack multiplayer lobby.
/// Speaks the ClientMessage/ServerMessage JSON protocol from SharedModels.
@Observable
@MainActor
final class OnlineViewModel {
  enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
  }

  /// Fixed server address. The online lobby does not expose a writable
  /// address field — clients always talk to this one Blackjack server.
  private enum Server {
    static let host = "127.0.0.1:8080"
    static let http = "http://\(host)"
    static let ws = "ws://\(host)"
  }

  // MARK: - Published state

  var connectionState: ConnectionState = .disconnected
  var myID: UUID?
  var tableState: TableState?
  var errorMessage: String?
  /// The lobby this client is currently connected to (nil when not in a room).
  var currentLobby: LobbyInfo?

  // MARK: - Internals

  private var webSocketSession: URLSession?
  private var webSocketTask: URLSessionWebSocketTask?
  private var isReceiving = false
  /// True once the WebSocket handshake completed. Lets us skip a protocol
  /// close on sockets that never connected (which makes Network.framework log
  /// "copy_connected_local_endpoint on unconnected nw_connection").
  private var hasEstablishedConnection = false
  /// Becomes true while `disconnect()` tears the socket down on purpose, so the
  /// receive loop does not overwrite the clean `.disconnected` state with a
  /// spurious "connection lost" error (which used to make the lobby-browser
  /// task restart and double-refresh — the entry/leave flicker).
  private var intentionalDisconnect = false

  // MARK: - Computed helpers for views

  var isConnected: Bool {
    if case .connected = connectionState {
      return true
    }
    return false
  }

  var isConnecting: Bool {
    if case .connecting = connectionState {
      return true
    }
    return false
  }

  var myPlayer: PlayerState? {
    guard let myID else { return nil }
    return tableState?.players.first { $0.id == myID }
  }

  var opponents: [PlayerState] {
    guard let myID else { return tableState?.players ?? [] }
    return tableState?.players.filter { $0.id != myID } ?? []
  }

  var isMyTurn: Bool {
    guard let tableState, let myID, let me = myPlayer else { return false }
    return tableState.phase == .dealing
      && tableState.activePlayerID == myID
      && me.status == .playing
  }

  var isDealing: Bool {
    tableState?.phase == .dealing
  }

  var isSettled: Bool {
    tableState?.phase == .settled
  }

  var isLobby: Bool {
    tableState?.phase == .lobby
  }

  var dealerScoreText: String {
    guard let tableState else { return "0" }
    // Dealer's hand is fully hidden while a round is running.
    if isDealing {
      return "?"
    }
    return "\(tableState.dealerScore)"
  }

  var statusText: String {
    switch connectionState {
    case .disconnected: "Не підключено"
    case .connecting: "Підключення..."
    case .connected: "Підключено"
    case .failed: "Помилка з'єднання"
    }
  }

  // MARK: - Lobby browsing (REST)

  /// Fetches the list of available lobbies from the fixed server address.
  /// Uses a shared session — the browser polls this every few seconds, and
  /// creating a fresh URLSession per request churns memory for nothing.
  func fetchLobbies() async throws -> [LobbyInfo] {
    guard let url = URL(string: "\(Server.http)/lobbies") else { return [] }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode([LobbyInfo].self, from: data)
  }

  /// Creates a new lobby. An empty `name` makes the server auto-name it.
  func createLobby(name: String = "") async throws -> LobbyInfo {
    guard let url = URL(string: "\(Server.http)/lobbies") else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(["name": name])
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 || http.statusCode == 201 else {
      throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(LobbyInfo.self, from: data)
  }

  // MARK: - Connection

  /// Connects to a specific lobby via WebSocket, clears old state, then joins.
  /// Returns true when the socket is up (the join reply may still be in flight).
  func connect(lobbyInfo: LobbyInfo, name: String) async -> Bool {
    disconnect()

    guard let url = URL(string: "\(Server.ws)/ws/lobby/\(lobbyInfo.id.uuidString)") else {
      connectionState = .failed("Невірна адреса сервера")
      return false
    }

    connectionState = .connecting
    errorMessage = nil
    currentLobby = lobbyInfo
    intentionalDisconnect = false

    let session = URLSession(configuration: .default)
    webSocketSession = session
    let task = session.webSocketTask(with: url)
    webSocketTask = task
    task.resume()

    do {
      try await send(.join(name: name))
      // send() only succeeds once the handshake is done, so from here on a
      // protocol close in disconnect() is legitimate.
      hasEstablishedConnection = true
    } catch {
      connectionState = .failed("Не вдалося підключитися: \(error.localizedDescription)")
      // Tear down the dead task now instead of leaving it for a later
      // disconnect() to cancel while unconnected.
      isReceiving = false
      webSocketTask?.cancel()
      webSocketTask = nil
      webSocketSession?.invalidateAndCancel()
      webSocketSession = nil
      return false
    }

    receiveLoop()
    return true
  }

  func disconnect() {
    intentionalDisconnect = true
    isReceiving = false
    if hasEstablishedConnection {
      webSocketTask?.cancel(with: .goingAway, reason: nil)
    } else {
      // Never connected: plain cancel, no WebSocket close handshake.
      webSocketTask?.cancel()
    }
    hasEstablishedConnection = false
    webSocketTask = nil
    webSocketSession?.invalidateAndCancel()
    webSocketSession = nil
    myID = nil
    tableState = nil
    currentLobby = nil
    errorMessage = nil
    connectionState = .disconnected
  }

  // MARK: - Actions

  func startRound() {
    send(.startRound)
  }

  func hit() {
    send(.hit)
  }

  func stand() {
    send(.stand)
  }

  /// Sends the leave notice, gives it a moment to flush, then tears the
  /// socket down. (Cancelling immediately after a fire-and-forget send can
  /// drop the message and trips Network.framework's unconnected-endpoint log.)
  func leaveTable() {
    Task { [weak self] in
      try? await self?.send(.leave)
      try? await Task.sleep(for: .milliseconds(200))
      self?.disconnect()
    }
  }

  // MARK: - Haptic Feedback

  func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style)
      .impactOccurred()
  }

  // MARK: - Messaging

  @discardableResult
  private func send(_ message: ClientMessage) async throws {
    guard let webSocketTask else { throw URLError(.badURL) }
    let data = try JSONEncoder().encode(message)
    guard let text = String(data: data, encoding: .utf8) else { throw URLError(.cannotDecodeContentData) }
    try await webSocketTask.send(.string(text))
  }

  private func send(_ message: ClientMessage) {
    Task { try? await send(message) }
  }

  private func receiveLoop() {
    guard let webSocketTask, !isReceiving else { return }
    isReceiving = true

    Task { [weak self] in
      guard let self else { return }
      while isReceiving, self.webSocketTask === webSocketTask, webSocketTask.state == .running {
        do {
          let message = try await webSocketTask.receive()
          switch message {
          case let .string(text):
            if let data = text.data(using: .utf8),
               let serverMessage = try? JSONDecoder().decode(ServerMessage.self, from: data)
            {
              handle(serverMessage)
            }
          case let .data(data):
            if let serverMessage = try? JSONDecoder().decode(ServerMessage.self, from: data) {
              handle(serverMessage)
            }
          @unknown default:
            break
          }
        } catch {
          isReceiving = false
          self.webSocketTask = nil
          // A deliberate disconnect() already set `.disconnected`; don't
          // replace it with an error state (that flickered the browser list).
          if intentionalDisconnect {
            return
          }
          connectionState = .failed("З'єднання з сервером втрачено")
          return
        }
      }
      isReceiving = false
    }
  }

  private func handle(_ message: ServerMessage) {
    switch message {
    case let .welcome(playerID):
      myID = playerID
      connectionState = .connected
    case let .state(state):
      tableState = state
    case let .error(text):
      errorMessage = text
    }
  }
}

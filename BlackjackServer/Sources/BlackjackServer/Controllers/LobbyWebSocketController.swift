import NIOConcurrencyHelpers
import SharedModels
import Vapor

/// WebSocket endpoint for joining a specific multiplayer room.
/// Connect: `ws://host:8080/ws/lobby/:id`, then send/receive JSON-encoded
/// ClientMessage / ServerMessage values from SharedModels.
///
/// Each connection is bound to the room it joined; sockets live in the room
/// itself (`MultiplayerGameRoom.registerSocket`), so broadcasts never leak
/// between different lobbies.
final class LobbyWebSocketController: @unchecked Sendable {
  private let lobbyManager: LobbyManager

  init(lobbyManager: LobbyManager) {
    self.lobbyManager = lobbyManager
  }

  func register(on app: Application) {
    app.webSocket("ws", "lobby", ":id") { req, ws async in
      guard let idString = req.parameters.get("id"),
            let lobbyID = UUID(uuidString: idString)
      else {
        try? await ws.close()
        return
      }
      await self.handle(ws, lobbyID: lobbyID)
    }
  }

  private func handle(_ ws: WebSocket, lobbyID: UUID) async {
    guard let room = await lobbyManager.room(id: lobbyID) else {
      await send(.error("Стіл не знайдено"), to: ws)
      try? await ws.close()
      return
    }

    let playerIDBox = NIOLockedValueBox<UUID?>(nil)

    ws.onText { ws, text async in
      guard let data = text.data(using: .utf8),
            let message = try? JSONDecoder().decode(ClientMessage.self, from: data)
      else {
        await self.send(.error("Invalid message"), to: ws)
        return
      }
      await self.handleMessage(message, room: room, lobbyID: lobbyID, ws: ws, playerIDBox: playerIDBox)
    }

    ws.onClose.whenComplete { _ in
      guard let id = playerIDBox.withLockedValue({ $0 }) else { return }
      Task {
        await room.removePlayer(id: id)
        await room.unregisterSocket(playerID: id)
        await self.lobbyManager.notePlayerLeft(roomID: lobbyID)
      }
    }
  }

  private func handleMessage(_ message: ClientMessage, room: MultiplayerGameRoom, lobbyID: UUID,
                             ws: WebSocket, playerIDBox: NIOLockedValueBox<UUID?>) async
  {
    switch message {
    case let .join(name):
      switch await room.addPlayer(name: name) {
      case let .joined(id):
        playerIDBox.withLockedValue { $0 = id }
        await room.registerSocket(ws, playerID: id)
        await lobbyManager.notePlayerJoined(roomID: lobbyID)
        await send(.welcome(playerID: id), to: ws)
        await room.broadcastState()
      case .nameTaken:
        await send(.error("Це ім'я вже зайняте"), to: ws)
      case .tableFull:
        await send(.error("Стіл заповнений (макс. 5 гравців)"), to: ws)
      }

    case .startRound:
      await room.startRound()

    case .hit:
      if let id = playerIDBox.withLockedValue({ $0 }) {
        await room.hit(playerID: id)
      }

    case .stand:
      if let id = playerIDBox.withLockedValue({ $0 }) {
        await room.stand(playerID: id)
      }

    case .leave:
      if let id = playerIDBox.withLockedValue({ $0 }) {
        playerIDBox.withLockedValue { $0 = nil }
        await room.unregisterSocket(playerID: id)
        await room.removePlayer(id: id)
        await lobbyManager.notePlayerLeft(roomID: lobbyID)
        try? await ws.close()
      }
    }
  }

  private func send(_ message: ServerMessage, to ws: WebSocket) async {
    guard let data = try? JSONEncoder().encode(message),
          let text = String(data: data, encoding: .utf8) else { return }
    try? await ws.send(text)
  }
}

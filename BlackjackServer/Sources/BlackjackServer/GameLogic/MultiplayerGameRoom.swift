import Foundation
import SharedModels
import Vapor

/// Server-side authority for a single multiplayer blackjack table.
/// Runs rounds for up to `maxPlayers` human players against a dealer.
/// Each room owns its `WebSocket` connections so broadcasts never leak
/// between different lobbies.
actor MultiplayerGameRoom {
  private struct Player {
    var name: String
    var hand: [Card] = []
    var status: PlayerStatus = .waiting
    var isConnected = true
  }

  let id: UUID
  let maxPlayers: Int
  private var deck = Deck(deckCount: 8)
  private var players: [UUID: Player] = [:]
  private var dealerHand: [Card] = []
  private var phase: TablePhase = .lobby
  private var activePlayerID: UUID?
  private var sockets: [UUID: WebSocket] = [:]

  init(id: UUID = UUID(), maxPlayers: Int = 5) {
    self.id = id
    self.maxPlayers = maxPlayers
  }

  // MARK: - Metrics (for the lobby list)

  func playerCount() -> Int {
    players.count
  }

  func tablePhase() -> TablePhase {
    phase
  }

  func playerNames() -> [String] {
    players.map(\.value.name).sorted()
  }

  // MARK: - Socket registry

  func registerSocket(_ ws: WebSocket, playerID: UUID) {
    sockets[playerID] = ws
  }

  func unregisterSocket(playerID: UUID) {
    sockets[playerID] = nil
  }

  // MARK: - Lobby / Roster

  enum JoinResult {
    case joined(UUID)
    case nameTaken
    case tableFull
  }

  func addPlayer(name: String) -> JoinResult {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .nameTaken }
    if players.values.contains(where: { $0.name == trimmed }) {
      return .nameTaken
    }
    guard players.count < maxPlayers else { return .tableFull }
    let id = UUID()
    let displayName = trimmed.count > 16 ? String(trimmed.prefix(16)) : trimmed
    players[id] = Player(name: displayName)
    return .joined(id)
  }

  func removePlayer(id: UUID) {
    players[id]?.isConnected = false
    players[id]?.status = .stand
    // No active round: the seat frees up immediately.
    if phase == .lobby || phase == .settled {
      players[id] = nil
      if players.isEmpty {
        resetTable()
      } else {
        scheduleUpdate()
      }
      return
    }
    // A round is running. If this was the last player still sitting down, the
    // hand cannot continue (advanceTurn needs a connected player to act), so
    // abandon it: drop the ghost seats and return to the empty waiting state.
    // This lets notePlayerLeft() see an empty room and remove it from the
    // lobby list — otherwise a single player leaving mid-round leaves a
    // stranded room with a disconnected "ghost" player listed forever.
    if players.values.allSatisfy({ !$0.isConnected }) {
      players = players.filter(\.value.isConnected) // clears all ghosts
      dealerHand = []
      activePlayerID = nil
      phase = .lobby
      scheduleUpdate()
      return
    }
    scheduleUpdate()
    // Recover the game if the active player suddenly leaves (others remain).
    if activePlayerID == id {
      Task { advanceTurn() }
    }
  }

  /// Back to the empty waiting state (no rounds memorised once the room empties).
  private func resetTable() {
    dealerHand = []
    activePlayerID = nil
    phase = .lobby
    scheduleUpdate()
  }

  // MARK: - Round flow

  func startRound() {
    guard phase == .lobby || phase == .settled else { return }
    let seated = players.filter(\.value.isConnected).keys
    guard !seated.isEmpty else { return }

    deck = Deck(deckCount: 8)
    for key in seated {
      players[key]?.hand = [deck.getCard(), deck.getCard()]
      players[key]?.status = .playing
    }
    dealerHand = [deck.getCard(), deck.getCard()]
    phase = .dealing
    activePlayerID = nil
    scheduleUpdate()
    advanceTurn()
  }

  func hit(playerID: UUID) {
    guard phase == .dealing, activePlayerID == playerID else { return }
    guard players[playerID]?.status == .playing else { return }
    players[playerID]?.hand.append(deck.getCard())
    if players[playerID]!.hand.blackjackScore > 21 {
      players[playerID]?.status = .bust
    }
    scheduleUpdate()
    advanceTurn()
  }

  func stand(playerID: UUID) {
    guard phase == .dealing, activePlayerID == playerID else { return }
    guard players[playerID]?.status == .playing else { return }
    players[playerID]?.status = .stand
    scheduleUpdate()
    advanceTurn()
  }

  private func advanceTurn() {
    guard phase == .dealing, dealerHand.count == 2 else { return }
    let ordered = players.filter(\.value.isConnected).keys
      .sorted { $0.uuidString < $1.uuidString }
    guard !ordered.isEmpty else { return }

    // Natural blackjacks never act: they are settled automatically.
    for key in ordered where players[key]?.hand.count == 2 && players[key]?.hand.blackjackScore == 21 {
      if players[key]?.status == .playing {
        players[key]?.status = .blackjack
      }
    }

    let startIndex = ordered.firstIndex { $0 == activePlayerID }.map { $0 + 1 } ?? 0
    var next: UUID?
    for offset in 0 ..< ordered.count {
      let candidate = ordered[(startIndex + offset) % ordered.count]
      if players[candidate]?.status == .playing {
        next = candidate
        break
      }
    }

    if let next {
      activePlayerID = next
    } else {
      activePlayerID = nil
      dealerPlayThrough()
    }
    scheduleUpdate()
  }

  private func dealerPlayThrough() {
    while dealerHand.blackjackScore < 17 {
      dealerHand.append(deck.getCard())
    }
    settle()
  }

  private func settle() {
    defer { phase = .settled; activePlayerID = nil; scheduleUpdate() }
    let dealerScore = dealerHand.blackjackScore
    for (id, _) in players {
      let playerScore = players[id]!.hand.blackjackScore
      if players[id]!.status == .bust {
        players[id]!.status = .lost
      } else if dealerScore > 21 || playerScore > dealerScore {
        players[id]!.status = playerScore == 21 && players[id]!.hand.count == 2 ? .blackjack : .won
      } else if playerScore == dealerScore {
        players[id]!.status = .push
      } else {
        players[id]!.status = .lost
      }
    }
    // Disconnected players leave the table once the round is over.
    players = players.filter(\.value.isConnected)
  }

  // MARK: - Snapshot & broadcast

  func makeTableState() -> TableState {
    let playerStates = players.map { id, player in
      PlayerState(
        id: id,
        name: player.name,
        hand: player.hand,
        score: player.hand.blackjackScore,
        status: player.status,
        isConnected: player.isConnected
      )
    }

    return TableState(
      roomID: id,
      players: playerStates,
      dealerHand: dealerHand,
      dealerScore: dealerHand.blackjackScore,
      dealerHoleHidden: false,
      phase: phase,
      activePlayerID: activePlayerID,
      maxPlayers: maxPlayers
    )
  }

  /// Builds the snapshot sent to a single client. During a running round only
  /// the recipient's own hand is revealed; opponents' cards/scored and the
  /// dealer's hand stay hidden (face-down placeholders) until `settled`, so a
  /// snooping client can never read another seat's cards from the payload.
  private func maskedState(_ base: TableState, revealPlayerID: UUID?) -> TableState {
    guard base.phase == .dealing else { return base }

    let playersView = base.players.map { p in
      guard p.id != revealPlayerID else { return p }
      return PlayerState(
        id: p.id,
        name: p.name,
        hand: Array(repeating: .hidden, count: p.hand.count),
        score: 0,
        status: p.status,
        isConnected: p.isConnected
      )
    }

    return TableState(
      roomID: base.roomID,
      players: playersView,
      dealerHand: Array(repeating: .hidden, count: base.dealerHand.count),
      dealerScore: 0,
      dealerHoleHidden: true,
      phase: base.phase,
      activePlayerID: base.activePlayerID,
      maxPlayers: base.maxPlayers
    )
  }

  func sendState(to ws: WebSocket, for playerID: UUID?) async {
    let view = maskedState(makeTableState(), revealPlayerID: playerID)
    guard let data = try? JSONEncoder().encode(ServerMessage.state(view)),
          let text = String(data: data, encoding: .utf8) else { return }
    try? await ws.send(text)
  }

  func broadcastState() async {
    let base = makeTableState()
    for (playerID, ws) in sockets where !ws.isClosed {
      let view = maskedState(base, revealPlayerID: playerID)
      guard let data = try? JSONEncoder().encode(ServerMessage.state(view)),
            let text = String(data: data, encoding: .utf8) else { continue }
      try? await ws.send(text)
    }
  }

  private func scheduleUpdate() {
    Task { await self.broadcastState() }
  }
}

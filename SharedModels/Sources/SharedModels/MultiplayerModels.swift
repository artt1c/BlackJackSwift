import Foundation

// MARK: - Multiplayer player models

public enum PlayerStatus: String, Codable, Sendable {
  case waiting // joined, no round running
  case playing // round running, still can act
  case bust
  case stand
  case won
  case lost
  case push
  case blackjack
}

public struct PlayerState: Codable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let hand: [Card]
  public let score: Int
  public let status: PlayerStatus
  public let isConnected: Bool

  public init(id: UUID, name: String, hand: [Card], score: Int, status: PlayerStatus, isConnected: Bool) {
    self.id = id
    self.name = name
    self.hand = hand
    self.score = score
    self.status = status
    self.isConnected = isConnected
  }
}

public enum TablePhase: String, Codable, Sendable {
  case lobby // waiting for players / between rounds
  case dealing // round running
  case settled // round finished, results shown
}

public struct TableState: Codable, Sendable {
  public let roomID: UUID
  public let players: [PlayerState]
  public let dealerHand: [Card]
  public let dealerScore: Int
  public let dealerHoleHidden: Bool
  public let phase: TablePhase
  public let activePlayerID: UUID?
  public let maxPlayers: Int

  public init(roomID: UUID, players: [PlayerState], dealerHand: [Card], dealerScore: Int,
              dealerHoleHidden: Bool, phase: TablePhase, activePlayerID: UUID?, maxPlayers: Int)
  {
    self.roomID = roomID
    self.players = players
    self.dealerHand = dealerHand
    self.dealerScore = dealerScore
    self.dealerHoleHidden = dealerHoleHidden
    self.phase = phase
    self.activePlayerID = activePlayerID
    self.maxPlayers = maxPlayers
  }
}

// MARK: - Lobby listing (multiplayer)

/// Public summary of a multiplayer room, used by the lobby list / creation API.
public struct LobbyInfo: Codable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let playerCount: Int
  public let maxPlayers: Int
  public let phase: TablePhase
  /// Nicknames currently sitting at the table (for the lobby browser).
  public let playerNames: [String]

  public init(id: UUID, name: String, playerCount: Int, maxPlayers: Int, phase: TablePhase, playerNames: [String] = []) {
    self.id = id
    self.name = name
    self.playerCount = playerCount
    self.maxPlayers = maxPlayers
    self.phase = phase
    self.playerNames = playerNames
  }
}

// MARK: - WebSocket messages

public enum ClientMessage: Codable, Sendable {
  case join(name: String)
  case startRound
  case hit
  case stand
  case leave

  private enum CodingKeys: String, CodingKey { case type, name }
  private enum MessageType: String, Codable { case join, startRound, hit, stand, leave }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    switch try c.decode(MessageType.self, forKey: .type) {
    case .join: self = try .join(name: c.decode(String.self, forKey: .name))
    case .startRound: self = .startRound
    case .hit: self = .hit
    case .stand: self = .stand
    case .leave: self = .leave
    }
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .join(name):
      try c.encode(MessageType.join, forKey: .type)
      try c.encode(name, forKey: .name)
    case .startRound: try c.encode(MessageType.startRound, forKey: .type)
    case .hit: try c.encode(MessageType.hit, forKey: .type)
    case .stand: try c.encode(MessageType.stand, forKey: .type)
    case .leave: try c.encode(MessageType.leave, forKey: .type)
    }
  }
}

public enum ServerMessage: Codable, Sendable {
  case welcome(playerID: UUID)
  case state(TableState)
  case error(String)

  private enum CodingKeys: String, CodingKey { case type, playerID, state, message }
  private enum MessageType: String, Codable { case welcome, state, error }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    switch try c.decode(MessageType.self, forKey: .type) {
    case .welcome: self = try .welcome(playerID: c.decode(UUID.self, forKey: .playerID))
    case .state: self = try .state(c.decode(TableState.self, forKey: .state))
    case .error: self = try .error(c.decode(String.self, forKey: .message))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .welcome(id):
      try c.encode(MessageType.welcome, forKey: .type)
      try c.encode(id, forKey: .playerID)
    case let .state(s):
      try c.encode(MessageType.state, forKey: .type)
      try c.encode(s, forKey: .state)
    case let .error(m):
      try c.encode(MessageType.error, forKey: .type)
      try c.encode(m, forKey: .message)
    }
  }
}

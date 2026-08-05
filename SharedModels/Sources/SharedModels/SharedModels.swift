// The Swift Programming Language
// https://docs.swift.org/swift-book
public import Foundation

public enum Suit: String, Codable, CaseIterable, Sendable {
  case hearts, diamonds, clubs, spades
}

public enum Rank: Int, Codable, CaseIterable, Sendable {
  case two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10
  case jack = 12, queen = 13, king = 14, ace = 11
}

public enum GameStatus: String, Codable, Sendable {
  case waiting
  case playing
  case playerWon
  case dealerWon
  case tie
  case bust
}

public struct Card: Codable, Sendable {
  public let suit: Suit
  public let rank: Rank
  /// True for the face-down placeholder the server sends for cards that must
  /// stay hidden (opponents' hands and the dealer's hole) until the round ends.
  public let isHidden: Bool

  public init(suit: Suit, rank: Rank, isHidden: Bool = false) {
    self.suit = suit
    self.rank = rank
    self.isHidden = isHidden
  }

  /// A face-down card placeholder with the same size as a real card.
  public static let hidden = Card(suit: .spades, rank: .ace, isHidden: true)

  public var blackjackValue: Int {
    if rank == .ace {
      return 11
    }
    return min(rank.rawValue, 10)
  }
}

public extension [Card] {
  var blackjackScore: Int {
    var score = 0
    var aces = 0

    for card in self {
      score += card.blackjackValue
      if card.rank == .ace {
        aces += 1
      }
    }

    while score > 21, aces > 0 {
      score -= 10
      aces -= 1
    }

    return score
  }
}

public struct GameState: Codable, Sendable {
  public let id: UUID
  public let playerHand: [Card]
  public let dealerHand: [Card]
  public let playerScore: Int
  public let dealerScore: Int
  public let status: GameStatus

  public init(id: UUID, playerHand: [Card], dealerHand: [Card], playerScore: Int, dealerScore: Int, status: GameStatus) {
    self.id = id
    self.playerHand = playerHand
    self.dealerHand = dealerHand
    self.playerScore = playerScore
    self.dealerScore = dealerScore
    self.status = status
  }
}

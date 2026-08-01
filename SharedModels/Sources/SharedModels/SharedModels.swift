// The Swift Programming Language
// https://docs.swift.org/swift-book

public enum Suit: String, Codable, CaseIterable {
  case hearts, diamonds, clubs, spades
}

public enum Rank: Int, Codable, CaseIterable {
  case two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10
  case jack = 12, queen = 13, king = 14, ace = 11
}

public enum GameStatus: String, Codable {
  case waiting
  case playing
  case playerWon
  case dealerWon
  case tie
  case bust
}

public struct Card: Codable {
  public let suit: Suit
  public let rank: Rank

  public init(suit: Suit, rank: Rank) {
    self.suit = suit
    self.rank = rank
  }

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

public struct GameState: Codable {
  public let playerHand: [Card]
  public let dealerHand: [Card]
  public let playerScore: Int
  public let dealerScore: Int
  public let status: GameStatus

  public init(playerHand: [Card], dealerHand: [Card], playerScore: Int, dealerScore: Int, status: GameStatus) {
    self.playerHand = playerHand
    self.dealerHand = dealerHand
    self.playerScore = playerScore
    self.dealerScore = dealerScore
    self.status = status
  }
}

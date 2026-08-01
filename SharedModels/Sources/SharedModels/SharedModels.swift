// The Swift Programming Language
// https://docs.swift.org/swift-book

public enum Suit: String, Codable, CaseIterable {
  case hearts, diamonds, clubs, spades
}

public enum Rank: Int, Codable, CaseIterable {
  case ace = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10
  case jack = 11, queen = 12, king = 13

  public var blackjackValue: Int {
    min(rawValue, 10)
  }
}

public struct Card: Codable {
  public let suit: Suit
  public let rank: Rank

  public init(suit: Suit, rank: Rank) {
    self.suit = suit
    self.rank = rank
  }
}

public struct GameState: Codable {
  public let playerHand: [Card]
  public let dealerHand: [Card]
  public let playerScore: Int
  public let dealerScore: Int
  public let status: String

  public init(playerHand: [Card], dealerHand: [Card], playerScore: Int, dealerScore: Int, status: String) {
    self.playerHand = playerHand
    self.dealerHand = dealerHand
    self.playerScore = playerScore
    self.dealerScore = dealerScore
    self.status = status
  }
}

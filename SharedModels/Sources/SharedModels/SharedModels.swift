// The Swift Programming Language
// https://docs.swift.org/swift-book

enum Suit: String, Codable {
  case hearts, diamonds, clubs, spades
}

enum Rank: Int, Codable {
  case ace = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10
  case jack = 10, queen = 10, king = 10
}

struct Card: Codable {
  let suit: Suit
  let rank: Rank
}

struct GameState: Codable {
  let playerHand: [Card]
  let dealerHand: [Card]
  let playerScore: Int
  let dealerScore: Int
  let status: String // "playing", "player_won", "dealer_won", "bust"
}

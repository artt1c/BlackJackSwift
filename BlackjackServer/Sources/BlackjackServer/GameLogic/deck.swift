public import SharedModels

public struct Deck {
  private var cards: [Card] = []

  public init() {
    for suit in Suit.allCases {
      for rank in Rank.allCases {
        cards.append(Card(suit: suit, rank: rank))
      }
    }
  }

  public func getDeck() -> [Card] {
    cards
  }
}

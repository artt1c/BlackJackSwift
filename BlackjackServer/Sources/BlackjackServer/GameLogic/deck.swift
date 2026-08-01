public import SharedModels

public struct Deck {
  private var cards: [Card] = []

  public init() {
    for suit in Suit.allCases {
      for rank in Rank.allCases {
        cards.append(Card(suit: suit, rank: rank))
      }
    }
    shuffle()
  }

  public func getCard() throws -> Card {
    guard let randomCard = cards.randomElement() else {
      throw GameError.emptyDeck
    }
    return randomCard
  }

  public func getDeck() -> [Card] {
    cards
  }

  public mutating func shuffle() {
    cards.shuffle()
  }
}

public import SharedModels

public struct Deck {
  private var cards: [Card] = []
  private let deckCount: Int

  public init(deckCount: Int = 8) {
    self.deckCount = deckCount
    refreshDeck()
  }

  private mutating func refreshDeck() {
    var initialDeck: [Card] = []
    for suit in Suit.allCases {
      for rank in Rank.allCases {
        initialDeck.append(Card(suit: suit, rank: rank))
      }
    }

    cards = Array(repeating: initialDeck, count: deckCount).flatMap(\.self)
    shuffle()
  }

  public mutating func shuffle() {
    cards.shuffle()
  }

  public mutating func getCard() -> Card {
    if cards.count < deckCount * 26 {
      refreshDeck()
    }
    return cards.removeLast()
  }

  public func getDeck() -> [Card] {
    cards
  }
}

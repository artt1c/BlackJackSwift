public import SharedModels

public actor GameRoom {
  private var deck: Deck

  private var playerHand: [Card] = []
  private var dealerHand: [Card] = []

  private var playerScore: Int {
    playerHand.blackjackScore
  }

  private var dealerScore: Int {
    dealerHand.blackjackScore
  }

  private var gameStatus: GameStatus = .waiting

  private func determineWinner() {
    if dealerScore > 21 {
      gameStatus = .playerWon
    } else if dealerScore > playerScore {
      gameStatus = .dealerWon
    } else if dealerScore < playerScore {
      gameStatus = .playerWon
    } else {
      gameStatus = .tie
    }
  }

  private func checkIfPlayerBust() {
    if playerScore > 21 {
      gameStatus = .bust
    }
  }

  private func checkNaturalBlackjack() {
    switch (playerScore, dealerScore) {
    case (21, 21):
      gameStatus = .tie
    case (21, _):
      gameStatus = .playerWon
    case (_, 21):
      gameStatus = .dealerWon
    default:
      break
    }
  }

  public init() {
    deck = Deck()
  }

  public func startGame() {
    playerHand = []
    dealerHand = []
    gameStatus = .playing

    playerHand.append(deck.getCard())
    playerHand.append(deck.getCard())
    dealerHand.append(deck.getCard())
    dealerHand.append(deck.getCard())

    checkNaturalBlackjack()
  }

  public func playerHit() {
    if gameStatus != .playing {
      return
    }
    playerHand.append(deck.getCard())
    checkIfPlayerBust()
  }

  public func playerStand() {
    if gameStatus != .playing {
      return
    }
    dealerTurn()
  }

  private func dealerTurn() {
    while dealerScore < 17 {
      dealerHand.append(deck.getCard())
    }
    determineWinner()
  }

  public func getGameState() -> GameState {
    GameState(playerHand: playerHand, dealerHand: dealerHand, playerScore: playerScore, dealerScore: dealerScore, status: gameStatus)
  }
}

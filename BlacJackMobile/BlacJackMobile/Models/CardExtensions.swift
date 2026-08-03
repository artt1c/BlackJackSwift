import SharedModels
import SwiftUI

// MARK: - Suit Extensions

public extension Suit {
  /// Unicode symbol for the suit
  var symbol: String {
    switch self {
    case .hearts: "♥️"
    case .diamonds: "♦️"
    case .clubs: "♣️"
    case .spades: "♠️"
    }
  }

  /// Indicates if suit is red (Hearts/Diamonds) or black (Clubs/Spades)
  var isRed: Bool {
    self == .hearts || self == .diamonds
  }

  /// Theme color for the suit
  var themeColor: Color {
    isRed ? .red : .black
  }
}

// MARK: - Rank Extensions

public extension Rank {
  /// Display symbol for rank (e.g. "A", "J", "Q", "K", or raw value number)
  var displaySymbol: String {
    switch self {
    case .ace: "A"
    case .jack: "J"
    case .queen: "Q"
    case .king: "K"
    default: "\(rawValue)"
    }
  }

  /// Standard string representation for asset lookup
  var assetName: String {
    switch self {
    case .ace: "ace"
    case .jack: "jack"
    case .queen: "queen"
    case .king: "king"
    default: String(rawValue)
    }
  }
}

// MARK: - Card Extensions

public extension Card {
  /// Asset image filename matching `Assets.xcassets/Cards`
  var imageName: String {
    "\(rank.assetName)_of_\(suit.rawValue)"
  }
}

// MARK: - GameStatus Extensions

public extension GameStatus {
  /// Localized title string for the status
  var title: String {
    switch self {
    case .waiting: "Очікування"
    case .playing: "Ваш хід"
    case .playerWon: "Ви виграли!"
    case .dealerWon: "Дилер виграв"
    case .tie: "Нічия!"
    case .bust: "Перебір (Bust)!"
    }
  }

  /// Theme color representing the game result
  var themeColor: Color {
    switch self {
    case .playerWon: Color.green
    case .dealerWon, .bust: Color.red
    case .tie: Color.orange
    default: Color.blue
    }
  }

  /// SF Symbol icon associated with the status
  var iconName: String {
    switch self {
    case .playerWon: "trophy.fill"
    case .dealerWon: "xmark.circle.fill"
    case .bust: "exclamationmark.triangle.fill"
    case .tie: "equal.circle.fill"
    default: "info.circle.fill"
    }
  }
}

import SharedModels
import SwiftUI

// MARK: - PlayerStatus UI helpers (Ukrainian)

extension PlayerStatus {
  var title: String {
    switch self {
    case .waiting: "Очікує"
    case .playing: "Ходить"
    case .bust: "Перебір"
    case .stand: "Стоїть"
    case .won: "Виграв"
    case .lost: "Програв"
    case .push: "Нічия"
    case .blackjack: "Блекджек!"
    }
  }

  var themeColor: Color {
    switch self {
    case .won, .blackjack: .green
    case .lost, .bust: .red
    case .push: .orange
    case .stand: .yellow
    case .playing: .blue
    case .waiting: .gray
    }
  }
}

/// Compact row for one player at the online table (used for opponents and self).
struct PlayerRowView: View {
  let player: PlayerState
  var isMe = false
  var isTurn = false
  /// True while a round is running for an opponent: their points stay hidden.
  var scoreHidden = false

  private var initials: String {
    let name = player.name
    guard let first = name.first else { return "?" }
    return String(first).uppercased()
  }

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      ZStack {
        Circle().fill(
          LinearGradient(
            colors: isMe ? [Color.yellow, Color.orange] : [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.2, blue: 0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        Text(initials)
          .font(.subheadline)
          .fontWeight(.heavy)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(width: 40, height: 40)

      // Name + status
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 5) {
          Text(player.name)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .lineLimit(1)
          if isMe {
            Text("ВИ")
              .font(.system(size: 9, weight: .black))
              .foregroundColor(.black)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Capsule().fill(Color.yellow))
          }
        }
        Text(player.status.title)
          .font(.caption2)
          .foregroundColor(player.status.themeColor)
          .opacity(player.status == .playing ? 1 : 0.85)
      }

      Spacer()

      // Compact cards
      HStack(spacing: -14) {
        if player.hand.isEmpty {
          Text("—")
            .font(.caption)
            .foregroundColor(.white.opacity(0.35))
        } else {
          ForEach(Array(player.hand.enumerated()), id: \.offset) { _, card in
            CardView(card: card, width: 38)
          }
        }
      }
      .frame(minWidth: 60, alignment: .trailing)
      .frame(height: 58)

      // Score badge
      VStack(spacing: 1) {
        Text(scoreHidden ? "?" : "\(player.score)")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(scoreHidden ? .white.opacity(0.5) : (player.hand.isEmpty ? .white.opacity(0.4) : .yellow))
        Text("очки")
          .font(.system(size: 9))
          .foregroundColor(.white.opacity(0.6))
      }
      .frame(width: 48)
    }
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(isTurn ? Color.yellow.opacity(0.16) : Color.black.opacity(0.32))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(
              isTurn ? Color.yellow.opacity(0.85) : Color.white.opacity(0.12),
              lineWidth: isTurn ? 1.5 : 1
            )
        )
    )
    .animation(.easeInOut(duration: 0.2), value: isTurn)
  }
}

#Preview {
  PlayerRowView(
    player: PlayerState(
      id: UUID(),
      name: "Олексій",
      hand: [
        Card(suit: .hearts, rank: .ace),
        Card(suit: .spades, rank: .king),
      ],
      score: 21,
      status: .playing,
      isConnected: true
    ),
    isMe: true
  )
  .padding()
  .background(Color.black)
}

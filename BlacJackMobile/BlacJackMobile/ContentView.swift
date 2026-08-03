import SharedModels
import SwiftUI

struct ContentView: View {
  @State private var viewModel = GameViewModel()

  var body: some View {
    VStack(spacing: 20) {
      Text("Blackjack")
        .font(.largeTitle)
        .fontWeight(.bold)

      if viewModel.isLoading {
        ProgressView("Завантаження...")
      }

      if let error = viewModel.errorMessage {
        Text("Помилка: \(error)")
          .foregroundColor(.red)
          .multilineTextAlignment(.center)
          .padding()
      }

      if let state = viewModel.gameState {
        // Секція Дилера
        VStack(alignment: .leading, spacing: 10) {
          Text("Дилер (Очки: \(state.dealerScore))")
            .font(.headline)
          HStack {
            ForEach(state.dealerHand, id: \.rank.rawValue) { card in
              CardView(card: card)
            }
          }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)

        // Секція Гравця
        VStack(alignment: .leading, spacing: 10) {
          Text("Гравець (Очки: \(state.playerScore))")
            .font(.headline)
          HStack {
            ForEach(state.playerHand, id: \.rank.rawValue) { card in
              CardView(card: card)
            }
          }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)

        // Статус гри
        Text("Статус: \(statusText(state.status))")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(statusColor(state.status))

        // Дії гравця
        if state.status == .playing {
          HStack(spacing: 20) {
            Button("Hit") {
              Task {
                await viewModel.hit()
              }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Button("Stand") {
              Task {
                await viewModel.stand()
              }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
          }
        } else {
          Button("Грати знову") {
            Task {
              await viewModel.createRoom()
            }
          }
          .buttonStyle(.borderedProminent)
          .tint(.green)
        }

      } else {
        // Якщо гра ще не створена
        Spacer()
        Button("Почати гру") {
          Task {
            await viewModel.createRoom()
          }
        }
        .font(.title2)
        .buttonStyle(.borderedProminent)
        .tint(.green)
        Spacer()
      }
    }
    .padding()
  }

  /// Переклад статусу гри
  private func statusText(_ status: GameStatus) -> String {
    switch status {
    case .waiting: "Очікування"
    case .playing: "Ваш хід"
    case .playerWon: "Ви виграли!"
    case .dealerWon: "Дилер виграв."
    case .tie: "Нічия!"
    case .bust: "Перебір (Bust)!"
    }
  }

  /// Колір для статусу гри
  private func statusColor(_ status: GameStatus) -> Color {
    switch status {
    case .playerWon: .green
    case .dealerWon, .bust: .red
    case .tie: .orange
    default: .primary
    }
  }
}

/// Простий вигляд для карти
struct CardView: View {
  let card: Card

  var body: some View {
    Image(imageName(for: card))
      .resizable()
      .scaledToFit()
      .frame(width: 70, height: 105)
  }

  private func imageName(for card: Card) -> String {
    let rankName = switch card.rank {
    case .ace: "ace"
    case .jack: "jack"
    case .queen: "queen"
    case .king: "king"
    default: String(card.rank.rawValue)
    }
    return "\(rankName)_of_\(card.suit.rawValue)"
  }
}

#Preview {
  ContentView()
}

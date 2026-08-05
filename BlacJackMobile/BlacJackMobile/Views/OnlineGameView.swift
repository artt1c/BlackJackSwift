import SharedModels
import SwiftUI

/// Multiplayer table: dealer on top, opponents below, your hand and controls at the bottom.
struct OnlineGameView: View {
  let viewModel: OnlineViewModel

  private var activePlayerID: UUID? {
    viewModel.tableState?.activePlayerID
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        // Dealer
        if let state = viewModel.tableState {
          HandSectionView(
            title: "ДИЛЕР",
            scoreText: viewModel.dealerScoreText,
            cards: state.dealerHand,
            isDealer: true,
            hideDealerCards: state.phase == .dealing && state.dealerHoleHidden
          )
        } else {
          emptySection
        }

        // Result banner when round is over
        if viewModel.isSettled, let me = viewModel.myPlayer {
          StatusBannerView(
            title: resultTitle(for: me),
            iconName: resultIcon(for: me),
            color: me.status.themeColor
          )
          .transition(.scale.combined(with: .opacity))
        }

        // Opponents
        if !viewModel.opponents.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Гравці за столом")
              .font(.caption)
              .fontWeight(.heavy)
              .foregroundColor(.white.opacity(0.7))
              .tracking(1.2)

            VStack(spacing: 8) {
              ForEach(viewModel.opponents) { player in
                PlayerRowView(
                  player: player,
                  isTurn: activePlayerID == player.id && player.status == .playing,
                  scoreHidden: viewModel.isDealing
                )
              }
            }
          }
        } else if viewModel.isLobby {
          waitingSection("Очікуємо інших гравців...")
        }

        // Your hand
        if let me = viewModel.myPlayer {
          HandSectionView(
            title: "ВИ",
            scoreText: "\(me.score)",
            cards: me.hand,
            isDealer: false,
            hideDealerCards: false
          )
        }

        // Controls
        controls
          .padding(.top, 4)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 20)
    }
  }

  // MARK: - Helpers

  private var emptySection: some View {
    waitingSection("Завантаження столу...")
  }

  private func waitingSection(_ text: String) -> some View {
    HStack(spacing: 10) {
      ProgressView()
        .tint(.yellow)
      Text(text)
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.7))
    }
    .frame(maxWidth: .infinity, minHeight: 80)
  }

  private var controls: some View {
    VStack(spacing: 12) {
      if viewModel.isDealing {
        if viewModel.isMyTurn {
          HStack(spacing: 20) {
            // HIT
            Button {
              viewModel.triggerHaptic(.light)
              viewModel.hit()
            } label: {
              Text("HIT")
                .font(.headline).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  LinearGradient(
                    colors: [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.08, green: 0.55, blue: 0.25)],
                    startPoint: .top, endPoint: .bottom
                  )
                )
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: .green.opacity(0.4), radius: 6, x: 0, y: 3)
            }

            // STAND
            Button {
              viewModel.triggerHaptic(.light)
              viewModel.stand()
            } label: {
              Text("STAND")
                .font(.headline).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  LinearGradient(
                    colors: [Color(red: 0.9, green: 0.3, blue: 0.25), Color(red: 0.7, green: 0.15, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                  )
                )
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: .red.opacity(0.4), radius: 6, x: 0, y: 3)
            }
          }
        } else {
          // Someone else's turn
          let name = viewModel.tableState?.players.first { $0.id == activePlayerID }?.name ?? "..."
          Text("Хід гравця «\(name)»...")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.yellow)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Color.black.opacity(0.4)))
        }
      } else if viewModel.isLobby || viewModel.isSettled {
        Button {
          viewModel.triggerHaptic(.medium)
          viewModel.startRound()
        } label: {
          HStack(spacing: 10) {
            Image(systemName: "play.fill")
            Text(viewModel.isLobby ? "Почати раунд" : "Наступний раунд")
          }
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
          )
          .clipShape(Capsule())
          .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
        }

        if viewModel.isLobby {
          Text("\(viewModel.tableState?.players.count ?? 0) / 5 гравців за столом")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
        }
      }

      // Leave table
      Button {
        viewModel.triggerHaptic(.light)
        viewModel.leaveTable()
      } label: {
        Label("Покинути стіл", systemImage: "rectangle.portrait.and.arrow.right")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.red.opacity(0.9))
          .padding(.vertical, 10)
      }
    }
    .padding(.horizontal, 24)
  }

  private func resultTitle(for player: PlayerState) -> String {
    switch player.status {
    case .won: player.score == 21 && (player.hand.count == 2) ? "Блекджек!" : "Ви виграли!"
    case .lost, .bust: "Ви програли"
    case .push: "Нічия"
    default: player.status.title
    }
  }

  private func resultIcon(for player: PlayerState) -> String {
    switch player.status {
    case .won: player.hand.count == 2 && player.score == 21 ? "crown.fill" : "trophy.fill"
    case .lost, .bust: "xmark.circle.fill"
    case .push: "equal.circle.fill"
    default: "info.circle.fill"
    }
  }
}

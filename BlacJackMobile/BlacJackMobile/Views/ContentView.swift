import SharedModels
import SwiftUI

struct ContentView: View {
  @State private var viewModel = GameViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      // 1. Background
      CasinoBackgroundView()

      VStack(spacing: 0) {
        // 2. Header Bar (with back button)
        HeaderView {
          dismiss()
        }
        .padding(.top, 10)
        .padding(.horizontal)

        Spacer()

        if viewModel.isLoading, viewModel.gameState == nil {
          ProgressView()
            .controlSize(.large)
            .tint(.yellow)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
          Spacer()
        } else if viewModel.gameState != nil {
          // 3. Game Table Content
          VStack(spacing: 24) {
            // Dealer Hand (hides cards > 0 while playing)
            HandSectionView(
              title: "ДИЛЕР",
              scoreText: viewModel.displayedDealerScore,
              cards: viewModel.dealerHand,
              isDealer: true,
              hideDealerCards: !viewModel.isGameOver
            )

            Divider()
              .background(Color.yellow.opacity(0.3))
              .padding(.horizontal, 40)

            // Status Banner Overlay
            if viewModel.isGameOver {
              StatusBannerView(
                title: viewModel.statusText,
                iconName: viewModel.statusIcon,
                color: viewModel.statusColor
              )
              .transition(.scale.combined(with: .opacity))
            }

            // Player Hand
            HandSectionView(
              title: "ГРАВЕЦЬ",
              scoreText: viewModel.displayedPlayerScore,
              cards: viewModel.playerHand,
              isDealer: false,
              hideDealerCards: false
            )
          }
          .padding(.horizontal, 16)

          Spacer()

          // 4. Action Controls Bar
          ActionControlsView(viewModel: viewModel)
            .padding(.bottom, 20)
        } else {
          // 5. Initial Welcome Screen
          WelcomeView(viewModel: viewModel)
          Spacer()
        }
      }

      // Error Toast Overlay
      if let error = viewModel.errorMessage {
        VStack {
          Text("Помилка: \(error)")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(.top, 50)
          Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }
}

#Preview {
  ContentView()
}

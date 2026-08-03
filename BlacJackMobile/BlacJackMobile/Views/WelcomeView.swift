import SwiftUI

struct WelcomeView: View {
  let viewModel: GameViewModel

  var body: some View {
    VStack(spacing: 25) {
      Spacer()

      Image(systemName: "suit.diamond.fill")
        .font(.system(size: 70))
        .foregroundStyle(
          LinearGradient(
            colors: [.yellow, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .shadow(color: .orange.opacity(0.5), radius: 10)

      Text("Ласкаво просимо до Blackjack!")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)

      Button(action: {
        viewModel.triggerHaptic(.medium)
        Task {
          await viewModel.createRoom()
        }
      }) {
        HStack {
          Image(systemName: "play.fill")
          Text("Почати гру")
        }
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.black)
        .padding(.vertical, 14)
        .padding(.horizontal, 36)
        .background(
          LinearGradient(
            colors: [Color.yellow, Color.orange],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .clipShape(Capsule())
        .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
      }

      Spacer()
    }
  }
}

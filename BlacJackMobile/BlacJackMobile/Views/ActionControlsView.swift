import SwiftUI

struct ActionControlsView: View {
  let viewModel: GameViewModel

  var body: some View {
    HStack(spacing: 20) {
      if viewModel.isPlaying {
        // HIT Button
        Button(action: {
          viewModel.triggerHaptic(.light)
          Task {
            await viewModel.hit()
          }
        }) {
          HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
            Text("HIT")
          }
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(
              colors: [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.08, green: 0.55, blue: 0.25)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .clipShape(Capsule())
          .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
          .shadow(color: .green.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .disabled(viewModel.isLoading)

        // STAND Button
        Button(action: {
          viewModel.triggerHaptic(.light)
          Task {
            await viewModel.stand()
          }
        }) {
          HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
            Text("STAND")
          }
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(
              colors: [Color(red: 0.9, green: 0.3, blue: 0.25), Color(red: 0.7, green: 0.15, blue: 0.1)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .clipShape(Capsule())
          .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
          .shadow(color: .red.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .disabled(viewModel.isLoading)

      } else {
        // PLAY AGAIN Button
        Button(action: {
          viewModel.triggerHaptic(.medium)
          Task {
            await viewModel.createRoom()
          }
        }) {
          HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise")
            Text("Грати знову")
          }
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(
              colors: [.yellow, .orange],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .clipShape(Capsule())
          .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
      }
    }
    .padding(.horizontal, 24)
  }
}

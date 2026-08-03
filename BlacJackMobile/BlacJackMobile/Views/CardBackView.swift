import SwiftUI

struct CardBackView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(
          LinearGradient(
            colors: [Color(red: 0.12, green: 0.22, blue: 0.55), Color(red: 0.05, green: 0.1, blue: 0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      RoundedRectangle(cornerRadius: 6)
        .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
        .padding(3)

      VStack {
        Image(systemName: "suit.spade.fill")
          .font(.title2)
          .foregroundColor(.yellow.opacity(0.85))
      }
    }
    .frame(width: 72, height: 108)
    .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 3)
  }
}

#Preview {
  CardBackView()
}

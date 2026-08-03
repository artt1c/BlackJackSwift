import SwiftUI

struct HeaderView: View {
  var body: some View {
    HStack {
      Image(systemName: "suit.spade.fill")
        .foregroundColor(.yellow)
        .font(.title2)

      Text("BLACKJACK")
        .font(.system(size: 24, weight: .black, design: .serif))
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 2)

      Image(systemName: "suit.club.fill")
        .foregroundColor(.yellow)
        .font(.title2)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 20)
    .background(
      Capsule()
        .fill(Color.black.opacity(0.4))
        .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1.5))
    )
  }
}

#Preview {
  HeaderView()
}

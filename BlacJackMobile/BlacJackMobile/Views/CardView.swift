import SharedModels
import SwiftUI

struct CardView: View {
  let card: Card
  var width: CGFloat = 72

  var body: some View {
    Group {
      if card.isHidden {
        // Face-down placeholder (opponents / dealer hole). Sized by the frame.
        ZStack {
          RoundedRectangle(cornerRadius: 6)
            .fill(
              LinearGradient(
                colors: [Color(red: 0.12, green: 0.22, blue: 0.55), Color(red: 0.05, green: 0.1, blue: 0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          RoundedRectangle(cornerRadius: 5)
            .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
            .padding(2)
          Image(systemName: "suit.spade.fill")
            .foregroundColor(.yellow.opacity(0.85))
        }
      } else if UIImage(named: card.imageName) != nil {
        Image(card.imageName)
          .resizable()
          .scaledToFit()
      } else {
        VectorCardView(card: card)
      }
    }
    .frame(width: width, height: width * 1.5)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 3)
  }
}

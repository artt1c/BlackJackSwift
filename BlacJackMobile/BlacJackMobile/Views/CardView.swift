import SharedModels
import SwiftUI

struct CardView: View {
  let card: Card

  var body: some View {
    Group {
      if UIImage(named: card.imageName) != nil {
        Image(card.imageName)
          .resizable()
          .scaledToFit()
      } else {
        VectorCardView(card: card)
      }
    }
    .frame(width: 72, height: 108)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 3)
  }
}

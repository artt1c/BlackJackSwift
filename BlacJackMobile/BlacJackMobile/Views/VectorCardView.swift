import SharedModels
import SwiftUI

struct VectorCardView: View {
  let card: Card

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.white)

      VStack {
        HStack {
          VStack(spacing: 0) {
            Text(card.rank.displaySymbol)
              .font(.system(size: 13, weight: .bold))
            Text(card.suit.symbol)
              .font(.system(size: 11))
          }
          .foregroundColor(card.suit.themeColor)
          Spacer()
        }
        .padding(4)

        Spacer()

        Text(card.suit.symbol)
          .font(.system(size: 26))
          .foregroundColor(card.suit.themeColor)

        Spacer()

        HStack {
          Spacer()
          VStack(spacing: 0) {
            Text(card.suit.symbol)
              .font(.system(size: 11))
            Text(card.rank.displaySymbol)
              .font(.system(size: 13, weight: .bold))
          }
          .foregroundColor(card.suit.themeColor)
          .rotationEffect(.degrees(180))
        }
        .padding(4)
      }
    }
  }
}

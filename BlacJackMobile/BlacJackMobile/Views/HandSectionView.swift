import SharedModels
import SwiftUI

struct HandSectionView: View {
  let title: String
  let scoreText: String
  let cards: [Card]
  let isDealer: Bool
  let hideDealerCards: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with score badge
      HStack {
        Text(title)
          .font(.subheadline)
          .fontWeight(.heavy)
          .foregroundColor(.white.opacity(0.9))
          .tracking(1.5)

        Spacer()

        // Score Badge
        HStack(spacing: 4) {
          Text("Очки:")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.7))
          Text(scoreText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.yellow)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
          Capsule()
            .fill(Color.black.opacity(0.5))
            .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
        )
      }

      // Overlapping Cards View
      ZStack(alignment: .leading) {
        if cards.isEmpty {
          Text("Немає карт")
            .font(.caption)
            .foregroundColor(.white.opacity(0.5))
            .frame(height: 105)
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -32) {
              ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                if isDealer, hideDealerCards, index > 0 {
                  CardBackView()
                    .zIndex(Double(index))
                    .transition(.asymmetric(
                      insertion: .move(edge: .trailing).combined(with: .opacity),
                      removal: .opacity
                    ))
                } else {
                  CardView(card: card)
                    .zIndex(Double(index))
                    .transition(.asymmetric(
                      insertion: .move(edge: .trailing).combined(with: .opacity),
                      removal: .opacity
                    ))
                }
              }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
          }
        }
      }
      .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cards.count)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(Color.black.opacity(0.3))
        .overlay(
          RoundedRectangle(cornerRadius: 18)
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    )
  }
}

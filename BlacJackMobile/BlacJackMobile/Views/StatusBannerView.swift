import SwiftUI

struct StatusBannerView: View {
  let title: String
  let iconName: String
  let color: Color

  var body: some View {
    HStack {
      Image(systemName: iconName)
        .font(.title2)

      Text(title)
        .font(.title3)
        .fontWeight(.heavy)
    }
    .foregroundColor(.white)
    .padding(.vertical, 12)
    .padding(.horizontal, 24)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(color.opacity(0.9))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
    )
    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
  }
}

#Preview {
  StatusBannerView(title: "Ви виграли!", iconName: "trophy.fill", color: .green)
}

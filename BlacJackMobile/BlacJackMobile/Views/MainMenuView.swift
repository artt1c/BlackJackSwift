import SwiftUI

/// Mode selection screen: single player vs online multiplayer.
struct MainMenuView: View {
  var body: some View {
    ZStack {
      CasinoBackgroundView()

      VStack(spacing: 0) {
        HeaderView()
          .padding(.top, 12)
          .padding(.horizontal)

        Spacer()

        VStack(spacing: 14) {
          Image(systemName: "suit.diamond.fill")
            .font(.system(size: 56))
            .foregroundStyle(
              LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .shadow(color: .orange.opacity(0.5), radius: 10)

          Text("Оберіть режим гри")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)

          Text("Грайте наодинці або за одним столом з друзями")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
        }
        .padding(.bottom, 34)

        VStack(spacing: 16) {
          NavigationLink {
            ContentView()
          } label: {
            MenuButtonLabel(
              title: "Одиночна гра",
              subtitle: "Ви проти дилера",
              icon: "person.fill",
              colors: [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.08, green: 0.55, blue: 0.25)]
            )
          }

          NavigationLink {
            OnlineLobbyView()
          } label: {
            MenuButtonLabel(
              title: "Онлайн гра",
              subtitle: "Стол на кількох гравців",
              icon: "globe.europe.africa.fill",
              colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.08, green: 0.25, blue: 0.7)]
            )
          }
        }
        .padding(.horizontal, 24)

        Spacer()

        Text("Blackjack · v1.0")
          .font(.caption2)
          .foregroundColor(.white.opacity(0.4))
          .padding(.bottom, 16)
      }
    }
    .navigationBarHidden(true)
  }
}

/// Shared style for the two big mode buttons on the main menu.
private struct MenuButtonLabel: View {
  let title: String
  let subtitle: String
  let icon: String
  let colors: [Color]

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.white)
        .frame(width: 52, height: 52)
        .background(Circle().fill(Color.white.opacity(0.18)))

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.white)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.white.opacity(0.75))
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.subheadline)
        .fontWeight(.bold)
        .foregroundColor(.white.opacity(0.8))
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 18)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.white.opacity(0.25), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
  }
}

#Preview {
  MainMenuView()
}

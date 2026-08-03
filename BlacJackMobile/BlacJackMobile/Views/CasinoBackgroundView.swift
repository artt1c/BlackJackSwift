import SwiftUI

struct CasinoBackgroundView: View {
  var body: some View {
    ZStack {
      Color(red: 0.04, green: 0.18, blue: 0.09)
        .ignoresSafeArea()

      Image("background-cloth")
        .resizable(resizingMode: .tile)
        .opacity(0.25)
        .ignoresSafeArea()

      RadialGradient(
        gradient: Gradient(colors: [
          Color(red: 0.08, green: 0.42, blue: 0.22).opacity(0.8),
          Color(red: 0.02, green: 0.12, blue: 0.05).opacity(0.95),
        ]),
        center: .center,
        startRadius: 50,
        endRadius: 450
      )
      .ignoresSafeArea()
    }
  }
}

#Preview {
  CasinoBackgroundView()
}

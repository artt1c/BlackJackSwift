import SwiftUI

/// App root: owns the NavigationStack so every screen gets a back button.
struct RootView: View {
  var body: some View {
    NavigationStack {
      MainMenuView()
    }
    .tint(.yellow)
  }
}

#Preview {
  RootView()
}

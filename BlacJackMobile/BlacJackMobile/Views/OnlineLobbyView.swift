import SharedModels
import SwiftUI

/// Online mode entry: browse the lobbies on the server, create a new one, or
/// join an existing table. The server address is fixed — the app never asks
/// the user to type it.
struct OnlineLobbyView: View {
  @State private var viewModel = OnlineViewModel()
  @State private var playerName: String
  @State private var lobbies: [LobbyInfo] = []
  @State private var loadError: String?

  init() {
    let defaults = UserDefaults.standard
    _playerName = State(initialValue: defaults.string(forKey: "blackjack.playerName") ?? "Гравець")
  }

  var body: some View {
    ZStack {
      CasinoBackgroundView()

      if viewModel.isConnected {
        OnlineGameView(viewModel: viewModel)
          .transition(.opacity)
      } else {
        lobbyBrowser
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: viewModel.isConnected)
    .navigationTitle("Онлайн гра")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.hidden, for: .navigationBar)
    // Refresh the lobby list while browsing; stop once inside a table.
    // The loop is cancellation-aware: `.task(id:)` cancels it whenever
    // connectionState changes (join/leave), and a cancelled task must stop
    // polling. `try?` around Task.sleep used to swallow the cancellation and
    // left a zombie loop hammering GET /lobbies as fast as possible.
    .task(id: viewModel.connectionState) {
      while !Task.isCancelled, !viewModel.isConnected {
        await reload()
        do {
          try await Task.sleep(for: .seconds(3))
        } catch {
          return // cancelled or interrupted — stop polling
        }
      }
    }
  }

  // MARK: - Lobby browser

  private var lobbyBrowser: some View {
    ScrollView {
      VStack(spacing: 18) {
        Spacer(minLength: 4)

        Image(systemName: "person.3.fill")
          .font(.system(size: 44))
          .foregroundStyle(
            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
          )
          .shadow(color: .orange.opacity(0.5), radius: 10)

        Text("Виберіть стіл")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)

        // Nickname (needed to join any table).
        VStack(alignment: .leading, spacing: 6) {
          Text("Ваше ім'я")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.7))
          TextField("Гравець", text: $playerName)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.45))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            )
            .foregroundColor(.white)
        }

        // Create a new lobby.
        Button {
          viewModel.triggerHaptic(.medium)
          createAndJoin()
        } label: {
          HStack(spacing: 10) {
            Image(systemName: "plus")
            Text("Створити новий стіл")
          }
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
          .background(
            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
          )
          .clipShape(Capsule())
          .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isConnecting)

        // Lobby list.
        lobbyList
          .padding(.bottom, 8)
      }
      .padding(.horizontal, 24)
    }
  }

  private var lobbyList: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Доступні столи")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.white)
        Spacer()
        if loadError != nil || lobbies.isEmpty {
          Button {
            Task { await reload() }
          } label: {
            Image(systemName: "arrow.clockwise")
              .foregroundColor(.yellow)
          }
        }
      }

      if let error = loadError {
        Text(error)
          .font(.footnote)
          .foregroundColor(.red)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
      } else if lobbies.isEmpty {
        Text("Немає столів. Натисніть «Створити новий стіл».")
          .font(.footnote)
          .foregroundColor(.white.opacity(0.6))
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
      } else {
        ForEach(lobbies) { lobby in
          Button {
            viewModel.triggerHaptic(.light)
            join(lobby)
          } label: {
            LobbyRow(lobby: lobby)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  // MARK: - Actions

  private var trimmedName: String {
    playerName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func persistName() {
    UserDefaults.standard.set(playerName, forKey: "blackjack.playerName")
  }

  private func join(_ lobby: LobbyInfo) {
    guard !trimmedName.isEmpty else {
      loadError = "Вкажіть ваше ім'я, перш ніж приєднатися"
      return
    }
    persistName()
    Task {
      await viewModel.connect(lobbyInfo: lobby, name: trimmedName)
      if viewModel.errorMessage != nil {
        loadError = viewModel.errorMessage
      }
    }
  }

  private func createAndJoin() {
    guard !trimmedName.isEmpty else {
      loadError = "Вкажіть ваше ім'я, щоб створити стіл"
      return
    }
    loadError = nil
    persistName()
    Task {
      do {
        let lobby = try await viewModel.createLobby()
        await viewModel.connect(lobbyInfo: lobby, name: trimmedName)
        if viewModel.errorMessage != nil {
          loadError = viewModel.errorMessage
        }
      } catch {
        loadError = "Не вдалося створити стіл. Сервер недоступний?"
      }
    }
  }

  private func reload() async {
    do {
      lobbies = try await viewModel.fetchLobbies()
      loadError = nil
    } catch {
      // A reload interrupted by a state change (e.g. joining a table) throws
      // CancellationError/URLError(.cancelled) — not a real server failure.
      if Task.isCancelled {
        return
      }
      loadError = "Не вдалося зв'язатися з сервером"
    }
  }
}

/// One selectable lobby in the list.
private struct LobbyRow: View {
  let lobby: LobbyInfo

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "rectangle.on.rectangle.angled")
        .font(.title3)
        .foregroundColor(.yellow)
        .frame(width: 44, height: 44)
        .background(Circle().fill(Color.black.opacity(0.35)))

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(lobby.name)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .lineLimit(1)
          if lobby.playerCount > 0 {
            Text("\(lobby.playerCount)/\(lobby.maxPlayers)")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundColor(.black)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Capsule().fill(Color.yellow.opacity(0.9)))
          }
        }
        if lobby.playerNames.isEmpty {
          Text("Порожній стіл")
            .font(.caption)
            .foregroundColor(.white.opacity(0.5))
        } else {
          Text("За столом: \(lobby.playerNames.joined(separator: ", "))")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .lineLimit(1)
        }
      }

      Spacer()

      HStack(spacing: 6) {
        Circle()
          .fill(badgeColor)
          .frame(width: 8, height: 8)
        Text(badgeText)
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundColor(badgeColor)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Capsule().fill(badgeColor.opacity(0.16)))

      Image(systemName: "chevron.right")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.6))
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.black.opacity(0.4))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }

  private var badgeText: String {
    switch lobby.phase {
    case .lobby: "Очікування"
    case .dealing: "Гра триває"
    case .settled: "Роздачу завершено"
    }
  }

  private var badgeColor: Color {
    switch lobby.phase {
    case .lobby: .blue
    case .dealing: .green
    case .settled: .orange
    }
  }
}

#Preview {
  NavigationStack {
    OnlineLobbyView()
  }
}

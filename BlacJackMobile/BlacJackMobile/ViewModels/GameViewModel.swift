import SharedModels
import SwiftUI

@Observable
@MainActor
final class GameViewModel {
  // MARK: - Published State Properties

  var gameState: GameState?
  var errorMessage: String?
  var isLoading = false

  // MARK: - Computed Properties for View Binding

  var isPlaying: Bool {
    gameState?.status == .playing
  }

  var isGameOver: Bool {
    guard let status = gameState?.status else { return false }
    return status != .playing && status != .waiting
  }

  var dealerHand: [Card] {
    gameState?.dealerHand ?? []
  }

  var playerHand: [Card] {
    gameState?.playerHand ?? []
  }

  var dealerScore: Int {
    gameState?.dealerScore ?? 0
  }

  var playerScore: Int {
    gameState?.playerScore ?? 0
  }

  var displayedDealerScore: String {
    guard let state = gameState else { return "0" }
    if isGameOver {
      return "\(state.dealerScore)"
    } else {
      if let firstCard = state.dealerHand.first {
        return "\(firstCard.blackjackValue) + ?"
      }
      return "?"
    }
  }

  var displayedPlayerScore: String {
    "\(playerScore)"
  }

  var statusText: String {
    gameState?.status.title ?? "Готово до гри"
  }

  var statusColor: Color {
    gameState?.status.themeColor ?? .blue
  }

  var statusIcon: String {
    gameState?.status.iconName ?? "info.circle.fill"
  }

  // MARK: - API Network Requests

  private func getURL(path: String) -> URL {
    let urlString: String
    if let configURL = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String {
      urlString = configURL
    } else {
      #if DEBUG
        urlString = "http://localhost:8080"
      #else
        urlString = ""
      #endif
    }
    let fullURL = urlString + path
    guard let url = URL(string: fullURL) else {
      fatalError("Invalid URL configuration: \(fullURL)")
    }
    return url
  }

  private func performRequest<T: Decodable>(_ url: URL, method: String = "GET") async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
      throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(T.self, from: data)
  }

  // MARK: - User Intents & Actions

  func createRoom() async {
    isLoading = true
    errorMessage = nil
    do {
      struct CreateResponse: Decodable { let id: UUID }
      let url = getURL(path: "/game/new")
      let response: CreateResponse = try await performRequest(url, method: "POST")
      await getGameState(id: response.id)
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func hit() async {
    guard let id = gameState?.id else { return }
    isLoading = true
    errorMessage = nil
    do {
      let url = getURL(path: "/game/\(id.uuidString)/hit")
      gameState = try await performRequest(url, method: "POST")
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func stand() async {
    guard let id = gameState?.id else { return }
    isLoading = true
    errorMessage = nil
    do {
      let url = getURL(path: "/game/\(id.uuidString)/stand")
      gameState = try await performRequest(url, method: "POST")
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func getGameState(id: UUID) async {
    isLoading = true
    errorMessage = nil
    do {
      let url = getURL(path: "/game/\(id.uuidString)")
      gameState = try await performRequest(url, method: "GET")
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  // MARK: - Haptic Feedback Trigger

  func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
  }
}

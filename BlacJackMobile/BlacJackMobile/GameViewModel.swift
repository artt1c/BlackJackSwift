import SharedModels
import SwiftUI

@Observable
@MainActor
final class GameViewModel {
  var gameState: GameState?
  var errorMessage: String?
  var isLoading = false

  private func getURL() -> String {
    Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String ?? "http://localhost:8080"
  }

  private func getUrl(path: String) -> URL {
    guard let url = URL(string: getURL() + path) else {
      fatalError("Invalid URL")
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

  func createRoom() async {
    isLoading = true
    errorMessage = nil
    do {
      struct CreateResponse: Decodable { let id: UUID }
      let url = getUrl(path: "/game/new")
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
      let url = getUrl(path: "/game/\(id.uuidString)/hit")
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
      let url = getUrl(path: "/game/\(id.uuidString)/stand")
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
      let url = getUrl(path: "/game/\(id.uuidString)")
      gameState = try await performRequest(url, method: "GET")
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}

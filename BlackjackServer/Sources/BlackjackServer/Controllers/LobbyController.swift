import SharedModels
import Vapor

/// REST endpoints for discovering and creating multiplayer lobbies:
///
/// - `GET  /lobbies`  → `200` `[LobbyInfo]` (JSON)
/// - `POST /lobbies`  body `{ "name": "..." }` → `201` `LobbyInfo` (JSON)
///
/// Joining a lobby happens over WebSocket at `ws://host:8080/ws/lobby/:id`.
final class LobbyController: RouteCollection {
  private let lobbyManager: LobbyManager

  init(lobbyManager: LobbyManager) {
    self.lobbyManager = lobbyManager
  }

  struct CreateLobbyRequest: Content {
    let name: String?
  }

  func boot(routes: RoutesBuilder) throws {
    let lobbies = routes.grouped("lobbies")
    let lobbyManager = lobbyManager

    lobbies.get { _ async throws -> Response in
      let infos = await lobbyManager.list()
      return try Self.jsonResponse(infos, status: .ok)
    }

    lobbies.post { req async throws -> Response in
      let body = try req.content.decode(CreateLobbyRequest.self)
      guard let info = await lobbyManager.create(name: body.name) else {
        throw Abort(.conflict, reason: "Забагато столів на сервері")
      }
      return try Self.jsonResponse(info, status: .created)
    }
  }

  private static func jsonResponse(_ value: some Encodable, status: HTTPStatus) throws -> Response {
    let data = try JSONEncoder().encode(value)
    return Response(
      status: status,
      headers: ["content-type": "application/json"],
      body: .init(data: data)
    )
  }
}

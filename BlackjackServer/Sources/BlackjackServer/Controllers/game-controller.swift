public import Vapor
import SharedModels

extension GameState: @retroactive Content {}

struct GameController: RouteCollection {
  let gameService: GameService

  func boot(routes: RoutesBuilder) throws {
    let gameRoutes = routes.grouped("game")

    gameRoutes.post("new", use: createRoom)
    gameRoutes.get(":id", use: getGameState)
    gameRoutes.post(":id", "hit", use: playerHit)
    gameRoutes.post(":id", "stand", use: playerStand)
  }

  @Sendable
  func createRoom(req _: Request) async throws -> [String: String] {
    let id = await gameService.createRoom()
    await gameService.startGame(id: id)
    return ["id": id.uuidString]
  }

  @Sendable
  func getGameState(req: Request) async throws -> GameState {
    let id = try req.parameters.require("id", as: UUID.self)
    guard let gameState = await gameService.getGameState(id: id) else {
      throw Abort(.notFound, reason: "Game not found")
    }
    return gameState
  }

  @Sendable
  func playerHit(req: Request) async throws -> GameState {
    let id = try req.parameters.require("id", as: UUID.self)
    await gameService.playerHit(id: id)
    guard let gameState = await gameService.getGameState(id: id) else {
      throw Abort(.notFound, reason: "Game not found")
    }
    return gameState
  }

  @Sendable
  func playerStand(req: Request) async throws -> GameState {
    let id = try req.parameters.require("id", as: UUID.self)
    await gameService.playerStand(id: id)
    guard let gameState = await gameService.getGameState(id: id) else {
      throw Abort(.notFound, reason: "Game not found")
    }
    return gameState
  }
}

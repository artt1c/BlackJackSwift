import Vapor

func routes(_ app: Application) throws {
  let gameService = GameService()

  try app.register(collection: GameController(gameService: gameService))

  app.get { _ async in
    "It works!"
  }

  app.get("hello") { _ async -> String in
    "Hello, world!"
  }
}

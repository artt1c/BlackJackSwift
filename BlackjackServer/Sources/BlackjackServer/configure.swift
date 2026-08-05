import Vapor

/// configures your application
func configure(_ app: Application) async throws {
  // uncomment to serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  // register routes
  try routes(app)

  // multiplayer lobbies: REST list/create + per-lobby WebSocket
  let lobbyManager = LobbyManager()
  try app.register(collection: LobbyController(lobbyManager: lobbyManager))
  LobbyWebSocketController(lobbyManager: lobbyManager).register(on: app)
}

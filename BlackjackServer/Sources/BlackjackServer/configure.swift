import Vapor

/// configures your application
func configure(_ app: Application) async throws {
  // Browser clients need CORS to reach the REST API (vector: the web lobby at
  // localhost:5173 → 127.0.0.1:8080). WebSocket upgrades are not subject to
  // CORS, but the REST GET/POST /lobbies are.
  let cors = CORSMiddleware(configuration: .init(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin]
  ))
  app.middleware.use(cors, at: .beginning)

  // uncomment to serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  // register routes
  try routes(app)

  // multiplayer lobbies: REST list/create + per-lobby WebSocket
  let lobbyManager = LobbyManager()
  try app.register(collection: LobbyController(lobbyManager: lobbyManager))
  LobbyWebSocketController(lobbyManager: lobbyManager).register(on: app)
}

# BlackjackServer

💧 A project built with the Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

## Endpoints

### Single player (REST)

- `POST /game/new` — create a room, returns `{"id": "<uuid>"}`
- `GET  /game/:id` — current game state (`GameState`)
- `POST /game/:id/hit` — player hits, returns updated `GameState`
- `POST /game/:id/stand` — player stands, returns updated `GameState`

### Multiplayer (lobbies + WebSocket)

The server hosts multiple named lobbies. Discover and create them over REST,
then join one over WebSocket.

- `GET  /lobbies` → `200` JSON array of `LobbyInfo`
  `[{"id": "<uuid>", "name": "Стіл 1", "playerCount": 0, "playerNames": [], "maxPlayers": 5, "phase": "lobby"}]`
- `POST /lobbies` body `{"name": "..."}` (name optional → auto-named "Стіл N") →
  `201` `LobbyInfo`
- `ws://host:8080/ws/lobby/:id` — join the lobby with that id (up to 5 players).

Lifecycle & privacy:
- An empty lobby is deleted as soon as its last player leaves; a lobby that
  was created but never joined disappears after ~10 s. The list only shows
  lobbies people are actually in.
- `LobbyInfo.playerNames` lists who is currently seated at each table.
- While a round is running, state broadcasts hide every opponent's cards and
  points, and the dealer is fully face-down — nothing is revealed until the
  round settles. Masking happens server-side, so clients never receive
  another player's real hand mid-round.
  JSON messages defined in the `SharedModels` package (`MultiplayerModels.swift`):

Client → server (`ClientMessage`):
```json
{"type": "join", "name": "Олексій"}
{"type": "startRound"}
{"type": "hit"}
{"type": "stand"}
{"type": "leave"}
```

Server → client (`ServerMessage`):
```json
{"type": "welcome", "playerID": "<uuid>"}
{"type": "state", "state": { "phase": "lobby|dealing|settled", "players": [...], "dealerHand": [...], "activePlayerID": "<uuid>", ... }}
{"type": "error", "message": "..."}
```

Flow: join → welcome → everyone in the lobby presses "Почати раунд" → dealing →
each player hits/stands on their turn (`activePlayerID`) → dealer plays to 17 →
`settled` state with per-player `won / lost / push / blackjack` results →
start the next round the same way.

### Testing the multiplayer flow

With the server running:
```bash
node ws-test.js
```
Creates lobbies via the REST API, joins two clients to one lobby and plays a
full round (dealing, turn order, settlement, next-round restart), then verifies
multi-lobby isolation (a round in one lobby never leaks to another).

## Notes

- The server binds to `127.0.0.1:8080` by default. Use
  `swift run BlackjackServer serve --hostname 0.0.0.0 --port 8080` to expose it
  on your LAN so physical devices can join (enter the Mac's IP in the app's
  online lobby).

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community maintained packages](https://github.com/vapor-community)

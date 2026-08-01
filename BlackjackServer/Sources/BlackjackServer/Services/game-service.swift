public import Foundation
public import SharedModels

public actor GameService {
  private var rooms: [UUID: GameRoom] = [:]

  public func createRoom() -> UUID {
    let id = UUID()
    rooms[id] = GameRoom()
    return id
  }

  public func getRoom(id: UUID) -> GameRoom? {
    rooms[id]
  }

  public func getGameState(id: UUID) async -> GameState? {
    await rooms[id]?.getGameState()
  }

  public func playerHit(id: UUID) async {
    await rooms[id]?.playerHit()
  }

  public func playerStand(id: UUID) async {
    await rooms[id]?.playerStand()
  }

  public func startGame(id: UUID) async {
    await rooms[id]?.startGame()
  }
}

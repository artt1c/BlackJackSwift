import Foundation
import SharedModels
import Vapor

/// Manages the set of multiplayer rooms ("lobbies") on this server.
///
/// - `GET  /lobbies`  → `[LobbyInfo]`
/// - `POST /lobbies`  `{ "name": "..." }` → `LobbyInfo`
/// - WebSocket `ws://host:8080/ws/lobby/:id` to join a specific room.
actor LobbyManager {
  private struct Entry {
    let id: UUID
    let name: String
    var room: MultiplayerGameRoom
    let createdAt: Date
    /// Becomes true once at least one player has sat down. Empty rooms that
    /// were occupied are abandoned and get dropped on the next sweep.
    var everOccupied = false
  }

  /// Maximum number of simultaneous lobbies kept alive.
  private let maxLobbies = 20
  /// A room created but never joined is dropped after this long.
  private let neverJoinedGrace: TimeInterval = 10
  /// Sequential number used to auto-name lobbies created without a name.
  private var nextNumber = 1

  private var entries: [UUID: Entry] = [:]

  // MARK: - Occupancy events

  /// Called right after a player joined: marks the room as "was occupied" so
  /// it can never be mistaken for a never-joined room.
  func notePlayerJoined(roomID: UUID) {
    entries[roomID]?.everOccupied = true
  }

  /// Called right after a player left. If the room is now empty it is removed
  /// immediately — an abandoned lobby disappears from the list at once.
  func notePlayerLeft(roomID: UUID) async {
    guard let entry = entries[roomID] else { return }
    entries[roomID]?.everOccupied = true
    if await entry.room.playerCount() == 0 {
      entries[roomID] = nil
    }
  }

  // MARK: - Queries

  func list() async -> [LobbyInfo] {
    await sweepEmptyRooms()
    var result: [LobbyInfo] = []
    for entry in entries.values.sorted(by: { $0.createdAt < $1.createdAt }) {
      await result.append(info(for: entry))
    }
    return result
  }

  func room(id: UUID) -> MultiplayerGameRoom? {
    entries[id]?.room
  }

  private func info(for entry: Entry) async -> LobbyInfo {
    await LobbyInfo(
      id: entry.id,
      name: entry.name,
      playerCount: entry.room.playerCount(),
      maxPlayers: entry.room.maxPlayers,
      phase: entry.room.tablePhase(),
      playerNames: entry.room.playerNames()
    )
  }

  // MARK: - Creation

  /// Creates a new room, auto-naming it when `name` is empty.
  /// Returns `nil` if the server already hosts the maximum number of lobbies.
  func create(name: String? = nil) async -> LobbyInfo? {
    await sweepEmptyRooms()
    guard entries.count < maxLobbies else { return nil }

    let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let displayName: String = if trimmed.isEmpty {
      "Стіл \(nextNumber)"
    } else {
      trimmed.count > 24 ? String(trimmed.prefix(24)) : trimmed
    }
    nextNumber += 1

    let id = UUID()
    entries[id] = Entry(id: id, name: displayName, room: MultiplayerGameRoom(id: id), createdAt: Date())
    return LobbyInfo(id: id, name: displayName, playerCount: 0, maxPlayers: 5, phase: .lobby)
  }

  // MARK: - Cleanup

  /// Drops lobbies that no longer have anyone in them. This is a safety net
  /// for rooms that emptied without a clean leave event (e.g. everyone
  /// disconnected mid-round):
  /// - a room that once had players and is now empty is abandoned → removed;
  /// - a room created but never joined lives only for `neverJoinedGrace`.
  private func sweepEmptyRooms() async {
    let keys = Array(entries.keys)
    for id in keys {
      guard let entry = entries[id] else { continue }
      let count = await entry.room.playerCount()
      if count > 0 {
        entries[id]?.everOccupied = true
      } else if entry.everOccupied
        || Date().timeIntervalSince(entry.createdAt) > neverJoinedGrace
      {
        entries[id] = nil
      }
    }
  }
}

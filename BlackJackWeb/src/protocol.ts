// Wire types mirroring SharedModels (MultiplayerModels.swift + SharedModels.swift).
// Card.rank encodes as an Int raw value: 11 = ace, 12 = jack, 13 = queen, 14 = king.
// Suit encodes as a lowercase string. The server already masks opponents/dealer
// (cards sent with isHidden: true), so the client just renders what it gets.

export type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades'

export interface Card {
  suit: Suit
  rank: number
  isHidden: boolean
}

export type PlayerStatus =
  | 'waiting'
  | 'playing'
  | 'bust'
  | 'stand'
  | 'won'
  | 'lost'
  | 'push'
  | 'blackjack'

export interface PlayerState {
  id: string
  name: string
  hand: Card[]
  score: number
  status: PlayerStatus
  isConnected: boolean
}

export type TablePhase = 'lobby' | 'dealing' | 'settled'

export interface TableState {
  roomID: string
  players: PlayerState[]
  dealerHand: Card[]
  dealerScore: number
  dealerHoleHidden: boolean
  phase: TablePhase
  activePlayerID: string | null
  maxPlayers: number
}

export interface LobbyInfo {
  id: string
  name: string
  playerCount: number
  maxPlayers: number
  phase: TablePhase
  playerNames: string[]
}

// --- WebSocket messages (exact JSON shapes from the server) ---

export type ClientMessage =
  | { type: 'join'; name: string }
  | { type: 'startRound' }
  | { type: 'hit' }
  | { type: 'stand' }
  | { type: 'leave' }

export type ServerMessage =
  | { type: 'welcome'; playerID: string }
  | { type: 'state'; state: TableState }
  | { type: 'error'; message: string }

// --- Helpers ---

export function rankLabel(rank: number): string {
  if (rank === 11) return 'A'
  if (rank === 12) return 'J'
  if (rank === 13) return 'Q'
  if (rank === 14) return 'K'
  return String(rank)
}

export function suitSymbol(suit: Suit): string {
  return { hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠' }[suit]
}

export function isRedSuit(suit: Suit): boolean {
  return suit === 'hearts' || suit === 'diamonds'
}

/** Mirrors CardExtensions.imageName → "/cards/<rank>_of_<suit>.png". */
export function cardAssetName(card: Card): string {
  const label =
    card.rank === 11
      ? 'ace'
      : card.rank === 12
        ? 'jack'
        : card.rank === 13
          ? 'queen'
          : card.rank === 14
            ? 'king'
            : String(card.rank)
  return `${label}_of_${card.suit}.png`
}

export const playerStatusLabel: Record<PlayerStatus, string> = {
  waiting: 'Очікує',
  playing: 'Ходить',
  bust: 'Перебір',
  stand: 'Досить',
  won: 'Виграв',
  lost: 'Програв',
  push: 'Нічия',
  blackjack: 'Блекджек!',
}

export const phaseLabel: Record<TablePhase, string> = {
  lobby: 'Очікування',
  dealing: 'Гра триває',
  settled: 'Роздачу завершено',
}

// --- REST API (same-origin: proxied by Vite in dev, served by Vapor in prod) ---

export async function fetchLobbies(): Promise<LobbyInfo[]> {
  const res = await fetch('/lobbies')
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return (await res.json()) as LobbyInfo[]
}

export async function createLobby(name: string): Promise<LobbyInfo> {
  const res = await fetch('/lobbies', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return (await res.json()) as LobbyInfo
}

/** WebSocket URL to the local server, same-origin with the page. */
export function wsUrl(path: string): string {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws'
  return `${proto}://${location.host}${path}`
}
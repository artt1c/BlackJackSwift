import { useEffect, useRef, useState, useCallback } from 'react'
import {
  ClientMessage,
  LobbyInfo,
  ServerMessage,
  TableState,
  wsUrl,
} from './protocol'

export type ConnState = 'disconnected' | 'connecting' | 'connected' | 'error'

export interface Game {
  conn: ConnState
  error: string | null
  myID: string | null
  table: TableState | null
  lobby: LobbyInfo | null
  me: PlayerMe | null
  opponents: PlayerMe[]
  isConnected: boolean
  isMyTurn: boolean
  connect: (lobby: LobbyInfo, name: string) => void
  disconnect: () => void
  leave: () => void
  startRound: () => void
  hit: () => void
  stand: () => void
}

type PlayerMe = TableState['players'][number]

/** React binding over a single WebSocket to one lobby. Mirrors OnlineViewModel. */
export function useGame(): Game {
  const [conn, setConn] = useState<ConnState>('disconnected')
  const [error, setError] = useState<string | null>(null)
  const [myID, setMyID] = useState<string | null>(null)
  const [table, setTable] = useState<TableState | null>(null)
  const [lobby, setLobby] = useState<LobbyInfo | null>(null)

  const wsRef = useRef<WebSocket | null>(null)
  // True when we tear the socket down on purpose, so the close/error handlers
  // don't flip the UI into an "error" state on a deliberate leave.
  const intentionalRef = useRef(false)

  const send = useCallback((message: ClientMessage) => {
    wsRef.current?.send(JSON.stringify(message))
  }, [])

  // Stable handler used from both connect() and onmessage.
  const handleMessage = useCallback((raw: string) => {
    let m: ServerMessage
    try {
      m = JSON.parse(raw) as ServerMessage
    } catch {
      return
    }
    if (m.type === 'welcome') {
      setMyID(m.playerID)
      setConn('connected')
    } else if (m.type === 'state') {
      setTable(m.state)
    } else if (m.type === 'error') {
      setError(m.message)
    }
  }, [])

  const connect = useCallback(
    (lobbyInfo: LobbyInfo, name: string) => {
      // Tear down any previous socket cleanly.
      const old = wsRef.current
      if (old) {
        old.onclose = null
        old.onerror = null
        old.close()
      }
      intentionalRef.current = false
      wsRef.current = null

      setConn('connecting')
      setError(null)
      setMyID(null)
      setTable(null)
      setLobby(lobbyInfo)

      const ws = new WebSocket(wsUrl(`/ws/lobby/${lobbyInfo.id}`))
      wsRef.current = ws
      ws.onopen = () => ws.send(JSON.stringify({ type: 'join', name } satisfies ClientMessage))
      ws.onmessage = (e) => handleMessage(String(e.data))
      ws.onerror = () => {
        if (!intentionalRef.current) setConn('error')
      }
      ws.onclose = () => {
        if (!intentionalRef.current) setConn('error')
      }
    },
    [handleMessage],
  )

  const disconnect = useCallback(() => {
    intentionalRef.current = true
    const ws = wsRef.current
    wsRef.current = null
    if (ws) ws.close()
    setTable(null)
    setMyID(null)
    setLobby(null)
    setError(null)
    setConn('disconnected')
  }, [])

  // Fire the leave notice, give it a moment to flush, then close.
  const leave = useCallback(() => {
    send({ type: 'leave' })
    window.setTimeout(disconnect, 200)
  }, [send, disconnect])

  const startRound = useCallback(() => send({ type: 'startRound' }), [send])
  const hit = useCallback(() => send({ type: 'hit' }), [send])
  const stand = useCallback(() => send({ type: 'stand' }), [send])

  // Clean up the socket if the component ever unmounts while connected.
  useEffect(() => {
    return () => {
      intentionalRef.current = true
      wsRef.current?.close()
    }
  }, [])

  const isConnected = conn === 'connected'
  const me: PlayerMe | null = table ? table.players.find((p) => p.id === myID) ?? null : null
  const opponents = table ? table.players.filter((p) => p.id !== myID) : []
  const isMyTurn =
    !!table &&
    table.phase === 'dealing' &&
    table.activePlayerID === myID &&
    me?.status === 'playing'

  return {
    conn,
    error,
    myID,
    table,
    lobby,
    me,
    opponents,
    isConnected,
    isMyTurn,
    connect,
    disconnect,
    leave,
    startRound,
    hit,
    stand,
  }
}
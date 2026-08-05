import { useState } from 'react'
import { useGame } from './useGame'
import { LobbyBrowser } from './components/LobbyBrowser'
import { GameTable } from './components/GameTable'

export default function App() {
  const game = useGame()
  const [nickname, setNickname] = useState<string>(
    () => localStorage.getItem('blackjack.name') ?? '',
  )

  // Once we're connected and have a table snapshot we show the game, otherwise
  // the lobby browser. The browser reloads itself; the game is WS-driven.
  const inGame = game.isConnected && game.table !== null

  return (
    <div className="app-shell">
      {inGame ? (
        <GameTable game={game} nickname={nickname} />
      ) : (
        <LobbyBrowser
          game={game}
          nickname={nickname}
          onNickname={(n) => {
            setNickname(n)
            localStorage.setItem('blackjack.name', n)
          }}
        />
      )}
    </div>
  )
}
import { useEffect, useState } from 'react'
import { createLobby, fetchLobbies, LobbyInfo } from '../protocol'
import { Game } from '../useGame'
import { LobbyRow } from './LobbyRow'

interface Props {
  game: Game
  nickname: string
  onNickname: (n: string) => void
}

export function LobbyBrowser({ game, nickname, onNickname }: Props) {
  const [lobbies, setLobbies] = useState<LobbyInfo[]>([])
  const [loadError, setLoadError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function reload() {
    try {
      setLobbies(await fetchLobbies())
      setLoadError(null)
    } catch {
      setLoadError('Не вдалося зв’язатися з сервером')
    }
  }

  // Auto-refresh the list while the browser is on screen. Cleaned up on
  // unmount / when leaving — no lingering poller.
  useEffect(() => {
    reload()
    const id = window.setInterval(reload, 3000)
    return () => window.clearInterval(id)
  }, [])

  const trimmed = nickname.trim()

  async function handleCreate() {
    if (!trimmed) {
      setLoadError('Вкажіть ваше ім’я, щоб створити стіл')
      return
    }
    setBusy(true)
    try {
      const lobby = await createLobby(trimmed)
      game.connect(lobby, trimmed)
    } catch {
      setLoadError('Не вдалося створити стіл. Сервер недоступний?')
    } finally {
      setBusy(false)
    }
  }

  function handleJoin(lobby: LobbyInfo) {
    if (!trimmed) {
      setLoadError('Вкажіть ваше ім’я, перш ніж приєднатися')
      return
    }
    game.connect(lobby, trimmed)
  }

  const connectionNote = game.conn === 'error' ? 'Помилка з’єднання з сервером.' : null

  return (
    <div className="lobby">
      <header className="lobby-header">
        <div className="logo">
          <span className="logo-spade">♠</span>
          <h1>Блекджек</h1>
        </div>
        <p className="tagline">Онлайн багатокористувацька гра</p>
      </header>

      <section className="panel">
        <label className="field-label">Ваше ім’я</label>
        <input
          className="text-input"
          placeholder="Гравець"
          value={nickname}
          onChange={(e) => onNickname(e.target.value)}
          maxLength={16}
        />
      </section>

      <button className="btn btn-primary" onClick={handleCreate} disabled={busy || trimmed === ''}>
        Створити новий стіл
      </button>

      {connectionNote && <p className="error-note">{connectionNote}</p>}
      {loadError && <p className="error-note">{loadError}</p>}

      <section className="panel lobby-list">
        <div className="lobby-list-header">
          <h2>Доступні столи</h2>
          <button className="icon-btn" title="Оновити" onClick={() => reload()}>
            ⟳
          </button>
        </div>
        {lobbies.length === 0 ? (
          <p className="empty-note">Немає столів. Натисніть «Створити новий стіл».</p>
        ) : (
          lobbies.map((lobby) => (
            <LobbyRow key={lobby.id} lobby={lobby} onJoin={() => handleJoin(lobby)} />
          ))
        )}
      </section>
    </div>
  )
}
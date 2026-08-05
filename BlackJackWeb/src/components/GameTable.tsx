import { Game } from '../useGame'
import { Hand } from './Hand'
import { Seat } from './Seat'

interface Props {
  game: Game
  nickname: string
}

export function GameTable({ game, nickname }: Props) {
  const { table, me, opponents, isMyTurn, leave, startRound, hit, stand } = game
  if (!table) return null
  const t = table // non-null snapshot for the nested closure below

  const dealing = t.phase === 'dealing'
  const dealerScoreText = dealing ? '?' : String(t.dealerScore)
  const canStart = !dealing // lobby or settled

  // A seat's score chip: hidden ("?") for opponents while a round is dealing
  // (the server already sends masked cards + score 0); mine is always revealed.
  function seatScore(playerId: string, isMe: boolean): string | null {
    if (isMe) return String(me?.score ?? 0)
    const p = t.players.find((x) => x.id === playerId)
    if (!p || p.hand.length === 0) return null
    return dealing ? '?' : String(p.score)
  }

  return (
    <div className="table-wrap">
      <header className="table-header">
        <div className="table-title">
          <span className="table-dot">●</span>
          <span>{game.lobby?.name ?? 'Стіл'}</span>
        </div>
        <button className="btn btn-ghost" onClick={leave}>
          Покинути стіл
        </button>
      </header>

      <div className="felt">
        <div className="dealer-area">
          <div className="seat-label">Дилер</div>
          <Hand cards={table.dealerHand} width={70} overlap={40} />
          <div className={`score-chip ${dealing ? 'dim' : ''}`}>{dealerScoreText}</div>
        </div>

        <div className="players-area">
          {opponents.map((opp) => (
            <Seat
              key={opp.id}
              player={opp}
              scoreText={seatScore(opp.id, false)}
              active={table.activePlayerID === opp.id}
            />
          ))}
          {me && (
            <Seat
              key={me.id}
              player={me}
              scoreText={seatScore(me.id, true)}
              active={isMyTurn}
            />
          )}
        </div>
      </div>

      <div className="controls">
        {game.error && <p className="error-note">{game.error}</p>}

        {canStart ? (
          <button className="btn btn-primary btn-wide" onClick={startRound}>
            Почати роздачу
          </button>
        ) : isMyTurn ? (
          <>
            <span className="turn-hint">Ваш хід</span>
            <div className="btn-row">
              <button className="btn btn-hit" onClick={hit}>
                Взяти карту
              </button>
              <button className="btn btn-stand" onClick={stand}>
                Досить
              </button>
            </div>
          </>
        ) : (
          <p className="turn-hint">
            {table.activePlayerID
              ? `Хід: ${
                  opponents.find((o) => o.id === table.activePlayerID)?.name ?? 'суперника...'
                }`
              : 'Очікуйте...'}
          </p>
        )}
      </div>

      <p className="me-note">
        Ви граєте за столом <strong>{game.lobby?.name}</strong> як <strong>{nickname}</strong>
      </p>
    </div>
  )
}
import { PlayerState, playerStatusLabel } from '../protocol'
import { Hand } from './Hand'

interface Props {
  player: PlayerState
  /** The numeric score to display, or null to omit (waiting / hidden). */
  scoreText: string | null
  /** True when it is this seat's turn (gold ring). */
  active: boolean
}

/** One player seat at the table. */
export function Seat({ player, scoreText, active }: Props) {
  const status =
    player.status !== 'waiting' && player.status !== 'playing'
      ? playerStatusLabel[player.status]
      : null

  return (
    <div className={`seat${active ? ' seat-active' : ''}`}>
      <div className="seat-label">
        <span className="seat-name">{player.name}</span>
        {status && <span className="seat-status">{status}</span>}
      </div>
      <Hand cards={player.hand} width={52} overlap={27} />
      {scoreText !== null && <div className={`score-chip${active ? '' : ' dim'}`}>{scoreText}</div>}
    </div>
  )
}
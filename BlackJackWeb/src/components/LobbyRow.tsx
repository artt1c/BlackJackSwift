import { LobbyInfo, phaseLabel } from '../protocol'

interface Props {
  lobby: LobbyInfo
  onJoin: () => void
}

const badgeColor: Record<LobbyInfo['phase'], string> = {
  lobby: 'blue',
  dealing: 'green',
  settled: 'orange',
}

export function LobbyRow({ lobby, onJoin }: Props) {
  const countLabel = lobby.playerCount > 0 ? `${lobby.playerCount}/${lobby.maxPlayers}` : null
  const roster =
    lobby.playerNames.length > 0 ? `За столом: ${lobby.playerNames.join(', ')}` : 'Порожній стіл'

  return (
    <button className="lobby-row" onClick={onJoin}>
      <div className="row-main">
        <span className="row-icon">🎴</span>
        <div className="row-text">
          <div className="row-title">
            <span className="row-name">{lobby.name}</span>
            {countLabel && <span className="count-badge">{countLabel}</span>}
          </div>
          <span className="row-roster">{roster}</span>
        </div>
      </div>
      <div className="row-right">
        <span className={`phase-badge phase-${badgeColor[lobby.phase]}`}>
          {phaseLabel[lobby.phase]}
        </span>
        <span className="chevron">›</span>
      </div>
    </button>
  )
}
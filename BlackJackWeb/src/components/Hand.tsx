import { Card } from '../protocol'
import { CardView } from './CardView'

interface Props {
  cards: Card[]
  width?: number
  overlap?: number
}

/** A row / fan of cards with slight overlap. */
export function Hand({ cards, width = 62, overlap = 34 }: Props) {
  return (
    <div className="hand" style={{ height: Math.round(width * 1.5) }}>
      {cards.map((card, i) => (
        <div
          key={i}
          className="hand-card"
          style={{ marginLeft: i === 0 ? 0 : -overlap, zIndex: i }}
        >
          <CardView card={card} width={width} />
        </div>
      ))}
      {cards.length === 0 && <span className="hand-empty" />}
    </div>
  )
}
import { Card, cardAssetName } from '../protocol'

interface Props {
  card: Card
  width?: number
}

/** Renders a single card: the iOS artwork for faces, a CSS back when hidden. */
export function CardView({ card, width = 62 }: Props) {
  const height = Math.round(width * 1.5)

  if (card.isHidden) {
    return (
      <div className="card-back" style={{ width, height }} aria-label="Схована карта" />
    )
  }

  return (
    <img
      src={`/cards/${cardAssetName(card)}`}
      alt=""
      draggable={false}
      className="card-img"
      style={{ width, height }}
    />
  )
}
// Copies the card face PNGs from the iOS app's asset catalog into public/cards
// so the web client reuses the exact same artwork as the mobile app.
import { cpSync, existsSync, mkdirSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const srcRoot = join(
  __dirname,
  '..',
  '..',
  'BlacjackMobile',
  'BlacJackMobile',
  'Assets.xcassets',
  'Cards',
)
const dst = join(__dirname, '..', 'public', 'cards')
mkdirSync(dst, { recursive: true })

let n = 0
for (const entry of readdirSync(srcRoot, { withFileTypes: true })) {
  if (!entry.isDirectory() || !entry.name.endsWith('.imageset')) continue
  const base = entry.name.replace(/\.imageset$/, '')
  if (base.endsWith('2') || base.includes('joker')) continue // skip back/duplicate variants
  const png = join(srcRoot, entry.name, `${base}.png`)
  if (existsSync(png)) {
    cpSync(png, join(dst, `${base}.png`))
    n += 1
  }
}

console.log(`Copied ${n} card images to ${dst}`)
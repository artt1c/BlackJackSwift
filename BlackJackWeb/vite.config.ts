import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Dev server proxies the lobby REST API and WebSocket to the Blackjack server
// on 127.0.0.1:8080, so the web client talks same-origin (no CORS in dev, and
// the same made-up "relative /lobbies" URLs also work in production).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/lobbies': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/ws': { target: 'ws://127.0.0.1:8080', ws: true },
    },
  },
})
import { loadEnv } from "vite"
import { defineConfig } from "vite"
import { tanstackStart } from "@tanstack/react-start/plugin/vite"
import viteReact from "@vitejs/plugin-react"
import tailwindcss from "@tailwindcss/vite"

export default defineConfig(({ mode }) => {
  // Server functions read process.env. Vite only exposes VITE_* to the client, so load .env for the server here.
  // Variables already set in the shell win.
  process.env = { ...loadEnv(mode, process.cwd(), ""), ...process.env }
  return {
    server: { port: 3000 },
    resolve: { tsconfigPaths: true },
    plugins: [tailwindcss(), tanstackStart(), viteReact()],
  }
})

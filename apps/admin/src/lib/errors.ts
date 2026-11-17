/** Server errors arrive as "Title: detail". */
export function parseError(e: unknown): { title: string; detail: string } {
  const msg = e instanceof Error ? e.message : String(e)
  const i = msg.indexOf(": ")
  return i === -1 ? { title: "Something went wrong", detail: msg } : { title: msg.slice(0, i), detail: msg.slice(i + 2) }
}

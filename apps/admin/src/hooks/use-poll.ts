import { useCallback, useEffect, useRef, useState } from "react"

/** Loads on mount, then re-loads every `ms`. Keeps old data on screen while refreshing. */
export function usePoll<T>(load: () => Promise<T>, ms = 2000) {
  const [data, setData] = useState<T>()
  const [error, setError] = useState<Error>()
  const fn = useRef(load)
  fn.current = load

  const refresh = useCallback(async () => {
    try { setData(await fn.current()); setError(undefined) } catch (e) { setError(e as Error) }
  }, [])

  useEffect(() => {
    refresh()
    const t = setInterval(refresh, ms)
    return () => clearInterval(t)
  }, [refresh, ms])

  return { data, error, refresh }
}

import { useCallback, useEffect, useState } from "react"

export type Theme = "light" | "dark"

/** The class is first set by the inline script in the root route; this keeps it and the saved choice in sync. */
export function useTheme() {
  const [theme, setTheme] = useState<Theme>("light")
  useEffect(() => setTheme(document.documentElement.classList.contains("dark") ? "dark" : "light"), [])

  const toggle = useCallback(() => {
    const next: Theme = theme === "dark" ? "light" : "dark"
    document.documentElement.classList.toggle("dark", next === "dark")
    try { localStorage.setItem("theme", next) } catch { /* storage unavailable: choice lasts this session */ }
    setTheme(next)
  }, [theme])

  return [theme, toggle] as const
}

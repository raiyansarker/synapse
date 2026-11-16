import { useEffect, useState } from "react"

export type Route = "overview" | "payments"
const ROUTES: Route[] = ["overview", "payments"]
const read = (): Route => (ROUTES.find((r) => r === location.hash.slice(1)) ?? "overview")

export function useHashRoute() {
  const [route, setRoute] = useState<Route>(read)
  useEffect(() => {
    const on = () => setRoute(read())
    addEventListener("hashchange", on)
    return () => removeEventListener("hashchange", on)
  }, [])
  return [route, (r: Route) => { location.hash = r }] as const
}

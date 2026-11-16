export const taka = (n: number) =>
  "৳" + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })

export const takaShort = (n: number) =>
  n >= 1_000_000 ? `৳${(n / 1_000_000).toFixed(1)}M` : n >= 1_000 ? `৳${(n / 1_000).toFixed(1)}k` : `৳${n.toFixed(0)}`

export function ago(iso: string, now = Date.now()) {
  const s = Math.max(0, Math.round((now - new Date(iso).getTime()) / 1000))
  if (s < 60) return `${s}s ago`
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`
  return `${Math.floor(s / 86400)}d ago`
}

export const clock = (iso: string) =>
  new Date(iso).toLocaleString("en-GB", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit", second: "2-digit" })

export const shortId = (id: string) => id.slice(0, 8)

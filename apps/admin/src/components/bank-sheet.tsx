import { useEffect, useState } from "react"
import { toast } from "sonner"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { api, ApiError } from "@/lib/api"
import { ago, clock, taka } from "@/lib/format"
import { STATE_META, bankOf } from "@/lib/states"
import { cn } from "@/lib/utils"
import type { Bank, Payment } from "@/lib/types"
import { StateBadge } from "./state-badge"

export function BankStatus({ enabled }: { enabled: boolean }) {
  return (
    <Badge variant="outline" className={cn("gap-1.5 border-transparent font-medium", enabled ? "bg-ok/10 text-ok" : "bg-muted text-muted-foreground")}>
      <span className="size-1.5 rounded-full bg-current" />
      {enabled ? "Active" : "Disabled"}
    </Badge>
  )
}

export function bankStats(bank: Bank, payments: Payment[] = []) {
  const mine = payments.filter((p) => bankOf(p.sva) === bank.identifier || bankOf(p.rva) === bank.identifier)
  const sent = mine.filter((p) => bankOf(p.sva) === bank.identifier)
  const settled = sent.filter((p) => STATE_META[p.state].terminal)
  const ok = sent.filter((p) => p.state === "COMPLETED")
  return {
    mine,
    sent: sent.length,
    received: mine.filter((p) => bankOf(p.rva) === bank.identifier).length,
    rate: settled.length ? Math.round((ok.length / settled.length) * 100) : undefined,
    inFlight: mine.filter((p) => !STATE_META[p.state].terminal).length,
    volume: ok.reduce((n, p) => n + p.amount, 0),
  }
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border bg-background p-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className="text-lg font-semibold tnum">{value}</div>
    </div>
  )
}

export function BankSheet({ bank, payments, onClose, onChanged, onToggle, onOpenPayment }: {
  bank?: Bank; payments?: Payment[]; onClose: () => void; onChanged: () => void
  onToggle: (b: Bank) => void; onOpenPayment: (id: string) => void
}) {
  const [url, setUrl] = useState("")
  const [saving, setSaving] = useState(false)
  useEffect(() => { if (bank) setUrl(bank.baseUrl) }, [bank?.id, bank?.baseUrl])

  async function save() {
    if (!bank) return
    setSaving(true)
    try {
      await api.updateBank(bank.id, { baseUrl: url.trim() })
      toast.success("Base URL saved", { description: `Calls for @${bank.identifier} now go to ${url.trim()}` })
      onChanged()
    } catch (e) { toast.error((e as ApiError).title, { description: (e as ApiError).detail }) }
    finally { setSaving(false) }
  }

  const st = bank ? bankStats(bank, payments) : undefined

  return (
    <Sheet open={!!bank} onOpenChange={(o) => !o && onClose()}>
      <SheetContent className="w-full overflow-y-auto bg-card sm:max-w-md" onOpenAutoFocus={(e) => e.preventDefault()}>
        {bank && st && (
          <>
            <SheetHeader>
              <SheetTitle className="flex items-center gap-3 text-2xl">@{bank.identifier} <BankStatus enabled={bank.enabled} /></SheetTitle>
              <SheetDescription>Registered {clock(bank.createdAt)}. Last changed {ago(bank.updatedAt)}.</SheetDescription>
            </SheetHeader>
            <div className="space-y-6 px-4 pb-6">
              <div className="grid grid-cols-2 gap-3">
                <Stat label="Sent" value={String(st.sent)} />
                <Stat label="Received" value={String(st.received)} />
                <Stat label="Success on sent" value={st.rate === undefined ? "n/a" : `${st.rate}%`} />
                <Stat label="In flight" value={String(st.inFlight)} />
              </div>

              <div className="space-y-2">
                <Label htmlFor="baseUrl">Base URL</Label>
                <div className="flex gap-2">
                  <Input id="baseUrl" type="url" value={url} onChange={(e) => setUrl(e.target.value)} />
                  <Button onClick={save} disabled={saving || !url.trim() || url.trim() === bank.baseUrl}>Save</Button>
                </div>
                <p className="text-xs text-muted-foreground">The switch calls this address to debit, credit, and notify.</p>
              </div>

              <Separator />

              <div className="space-y-2">
                <h3 className="text-sm font-semibold">Status</h3>
                <p className="text-sm text-muted-foreground">
                  {bank.enabled
                    ? `New payments to or from @${bank.identifier} are accepted.`
                    : `New payments to or from @${bank.identifier} are refused with "Bank not found".`}
                </p>
                <Button variant={bank.enabled ? "outline" : "default"} className="w-full" onClick={() => onToggle(bank)}>
                  {bank.enabled ? "Disable bank" : "Enable bank"}
                </Button>
              </div>

              <Separator />

              <div className="space-y-2">
                <h3 className="text-sm font-semibold">Recent payments</h3>
                {st.mine.length === 0 && <p className="text-sm text-muted-foreground">No payments involve this bank yet.</p>}
                <ul className="divide-y">
                  {st.mine.slice(0, 6).map((p) => (
                    <li key={p.id}>
                      <button onClick={() => onOpenPayment(p.id)} className="flex w-full items-center justify-between gap-3 py-2.5 text-left text-sm outline-none focus-visible:bg-accent">
                        <span>
                          <span className="block font-medium tnum">{taka(p.amount)}</span>
                          <span className="text-muted-foreground">{p.sva} to {p.rva}</span>
                        </span>
                        <StateBadge state={p.state} />
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </>
        )}
      </SheetContent>
    </Sheet>
  )
}

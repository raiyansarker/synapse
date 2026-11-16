import { useState } from "react"
import { Plus } from "lucide-react"
import { toast } from "sonner"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Skeleton } from "@/components/ui/skeleton"
import { Switch } from "@/components/ui/switch"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { BankSheet, BankStatus, bankStats } from "@/components/bank-sheet"
import { api, ApiError } from "@/lib/api"
import { ago } from "@/lib/format"
import type { Bank, Payment } from "@/lib/types"

export function BanksPage({ banks, payments, refresh, addOpen, setAddOpen, onOpenPayment }: {
  banks?: Bank[]; payments?: Payment[]; refresh: () => void
  addOpen: boolean; setAddOpen: (o: boolean) => void; onOpenPayment: (id: string) => void
}) {
  const [handle, setHandle] = useState("")
  const [url, setUrl] = useState("")
  const [error, setError] = useState<ApiError>()
  const [selectedId, setSelectedId] = useState<string>()
  const [confirm, setConfirm] = useState<Bank>()

  async function setEnabled(b: Bank, enabled: boolean) {
    try {
      await api.updateBank(b.id, { enabled })
      toast(enabled ? `@${b.identifier} enabled` : `@${b.identifier} disabled`, {
        description: enabled ? "Payments to and from this bank are accepted again." : "Payments already in flight continue.",
      })
      setConfirm(undefined); refresh()
    } catch (e) { toast.error((e as ApiError).title, { description: (e as ApiError).detail }) }
  }
  // Enabling is safe and goes straight through. Disabling asks first.
  const requestToggle = (b: Bank) => (b.enabled ? setConfirm(b) : setEnabled(b, true))

  async function add(e: React.FormEvent) {
    e.preventDefault(); setError(undefined)
    try {
      const b = await api.createBank(handle.trim(), url.trim())
      toast.success(`@${b.identifier} registered`, { description: "Payments to this handle are accepted now." })
      setHandle(""); setUrl(""); setAddOpen(false); refresh(); setSelectedId(b.id)
    } catch (err) { setError(err as ApiError) }
  }

  const selected = banks?.find((b) => b.id === selectedId)

  return (
    <>
      <Card className="py-0">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-6">Handle</TableHead>
                <TableHead>Base URL</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Payments</TableHead>
                <TableHead>Changed</TableHead>
                <TableHead className="pr-6 text-right">Accepting</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {!banks && <TableRow><TableCell colSpan={6} className="px-6"><Skeleton className="h-5 w-full" /></TableCell></TableRow>}
              {banks?.length === 0 && <TableRow><TableCell colSpan={6} className="h-32 text-center text-muted-foreground">No banks registered. Add one so payments can resolve its handle.</TableCell></TableRow>}
              {banks?.map((b) => (
                <TableRow key={b.id} className="cursor-pointer" onClick={() => setSelectedId(b.id)}>
                  <TableCell className="pl-6 font-medium">@{b.identifier}</TableCell>
                  <TableCell className="text-muted-foreground">{b.baseUrl}</TableCell>
                  <TableCell><BankStatus enabled={b.enabled} /></TableCell>
                  <TableCell className="text-right tnum">{bankStats(b, payments).mine.length}</TableCell>
                  <TableCell className="text-muted-foreground">{ago(b.updatedAt)}</TableCell>
                  <TableCell className="pr-6 text-right" onClick={(e) => e.stopPropagation()}>
                    <Switch checked={b.enabled} onCheckedChange={() => requestToggle(b)} aria-label={`Accept payments for ${b.identifier}`} />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <BankSheet
        bank={selected} payments={payments} onChanged={refresh} onToggle={requestToggle}
        onClose={() => setSelectedId(undefined)}
        onOpenPayment={(id) => { setSelectedId(undefined); onOpenPayment(id) }}
      />

      <Dialog open={!!confirm} onOpenChange={(o) => !o && setConfirm(undefined)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Disable @{confirm?.identifier}?</DialogTitle>
            <DialogDescription>
              New payments to or from this bank will be refused. {confirm ? bankStats(confirm, payments).inFlight : 0} payments already in flight will keep going.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirm(undefined)}>Cancel</Button>
            <Button variant="destructive" onClick={() => confirm && setEnabled(confirm, false)}>Disable bank</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent className="sm:max-w-md">
          <form onSubmit={add} className="space-y-4">
            <DialogHeader>
              <DialogTitle>Add bank</DialogTitle>
              <DialogDescription>The switch calls this URL to debit, credit, and notify.</DialogDescription>
            </DialogHeader>
            {error && <Alert variant="destructive"><AlertTitle>{error.title}</AlertTitle><AlertDescription>{error.detail}</AlertDescription></Alert>}
            <div className="space-y-2">
              <Label htmlFor="handle">Handle</Label>
              <Input id="handle" placeholder="city" pattern="[a-z]+" title="Lowercase letters only" value={handle} onChange={(e) => setHandle(e.target.value)} required autoComplete="off" />
              <p className="text-xs text-muted-foreground">Appears after the @ in addresses, like raiyan@city. Lowercase letters only.</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="url">Base URL</Label>
              <Input id="url" type="url" placeholder="http://localhost:9090" value={url} onChange={(e) => setUrl(e.target.value)} required />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setAddOpen(false)}>Cancel</Button>
              <Button type="submit"><Plus /> Add bank</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </>
  )
}

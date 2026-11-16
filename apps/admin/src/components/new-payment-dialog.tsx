import { useState } from "react"
import { toast } from "sonner"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { api, ApiError } from "@/lib/api"

export function NewPaymentDialog({ open, onOpenChange, onCreated }: { open: boolean; onOpenChange: (o: boolean) => void; onCreated: () => void }) {
  const [sva, setSva] = useState("")
  const [rva, setRva] = useState("")
  const [amount, setAmount] = useState("")
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<ApiError>()

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setBusy(true); setError(undefined)
    try {
      const id = await api.createPayment({ sva: sva.trim(), rva: rva.trim(), amount: Number(amount) })
      toast.success("Payment accepted", { description: `Idempotency key ${id}` })
      setSva(""); setRva(""); setAmount("")
      onOpenChange(false); onCreated()
    } catch (err) {
      setError(err as ApiError)
    } finally { setBusy(false) }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={submit} className="space-y-4">
          <DialogHeader>
            <DialogTitle>New payment</DialogTitle>
            <DialogDescription>Sends a real payment request to the switch, as a bank would.</DialogDescription>
          </DialogHeader>
          {error && (
            <Alert variant="destructive">
              <AlertTitle>{error.title}</AlertTitle>
              <AlertDescription>{error.detail}</AlertDescription>
            </Alert>
          )}
          <div className="space-y-2">
            <Label htmlFor="sva">Payer address</Label>
            <Input id="sva" placeholder="raiyan@city" value={sva} onChange={(e) => setSva(e.target.value)} required autoComplete="off" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="rva">Payee address</Label>
            <Input id="rva" placeholder="nadia@ucb" value={rva} onChange={(e) => setRva(e.target.value)} required autoComplete="off" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="amount">Amount (৳)</Label>
            <Input id="amount" type="number" step="0.01" min="0.01" max="1000000" placeholder="1250.00" value={amount} onChange={(e) => setAmount(e.target.value)} required className="tnum" />
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button type="submit" disabled={busy}>{busy ? "Sending…" : "Send payment"}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

import { useMutation, useQueryClient } from "@tanstack/react-query"
import { useNavigate } from "@tanstack/react-router"
import { useState } from "react"
import { toast } from "sonner"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { createPayment } from "@/lib/api"
import { parseError } from "@/lib/errors"

export function NewPaymentDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (o: boolean) => void }) {
  const [sva, setSva] = useState("")
  const [rva, setRva] = useState("")
  const [amount, setAmount] = useState("")
  const queryClient = useQueryClient()
  const navigate = useNavigate()

  const send = useMutation({
    mutationFn: () => createPayment({ data: { sva: sva.trim(), rva: rva.trim(), amount: Number(amount) } }),
    onSuccess: async (id) => {
      toast.success("Payment accepted", { description: `Idempotency key ${id}` })
      setSva(""); setRva(""); setAmount("")
      onOpenChange(false)
      await queryClient.invalidateQueries({ queryKey: ["payments"] })
      navigate({ to: "/payments" })
    },
  })
  const error = send.error ? parseError(send.error) : undefined

  function submit(e: React.FormEvent) {
    e.preventDefault()
    send.mutate()
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
            <Button type="submit" disabled={send.isPending}>{send.isPending ? "Sending…" : "Send payment"}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

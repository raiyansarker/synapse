import { useState } from "react"
import { RefreshCw } from "lucide-react"
import { toast } from "sonner"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { api, ApiError } from "@/lib/api"
import { clock, taka } from "@/lib/format"
import { STATE_META } from "@/lib/states"
import type { Payment } from "@/lib/types"
import { Lifecycle } from "./lifecycle"
import { StateBadge } from "./state-badge"

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-baseline justify-between gap-4 text-sm">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="text-right font-medium break-all">{children}</dd>
    </div>
  )
}

export function PaymentSheet({ payment, onClose }: { payment?: Payment; onClose: () => void }) {
  const [checking, setChecking] = useState(false)

  async function check() {
    if (!payment) return
    setChecking(true)
    try {
      const s = await api.getPaymentState(payment.id)
      toast(`Switch reports: ${STATE_META[s].label}`, { description: `GET /api/pay/${payment.id}` })
    } catch (e) {
      toast.error((e as ApiError).title, { description: (e as ApiError).detail })
    } finally { setChecking(false) }
  }

  return (
    <Sheet open={!!payment} onOpenChange={(o) => !o && onClose()}>
      <SheetContent className="w-full overflow-y-auto bg-card sm:max-w-md">
        {payment && (
          <>
            <SheetHeader>
              <SheetTitle className="text-2xl tnum">{taka(payment.amount)}</SheetTitle>
              <SheetDescription className="break-all">{payment.id}</SheetDescription>
            </SheetHeader>
            <div className="space-y-6 px-4 pb-6">
              <div className="space-y-2">
                <StateBadge state={payment.state} />
                <p className="text-sm text-muted-foreground">{STATE_META[payment.state].note}</p>
              </div>
              <dl className="space-y-2">
                <Field label="Payer">{payment.sva}</Field>
                <Field label="Payee">{payment.rva}</Field>
                <Field label="Created">{clock(payment.createdAt)}</Field>
                <Field label="Last change">{clock(payment.updatedAt)}</Field>
              </dl>
              <Separator />
              <div className="space-y-3">
                <h3 className="text-sm font-semibold">Path through the switch</h3>
                <Lifecycle state={payment.state} />
                <p className="text-xs text-muted-foreground">The ledger stores only the latest state, so earlier steps are inferred from it.</p>
              </div>
              <Button variant="outline" className="w-full" onClick={check} disabled={checking}>
                <RefreshCw className={checking ? "animate-spin" : ""} /> Check state on the switch
              </Button>
            </div>
          </>
        )}
      </SheetContent>
    </Sheet>
  )
}

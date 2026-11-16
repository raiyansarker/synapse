import { Check, Circle, Loader2, X } from "lucide-react"
import { cn } from "@/lib/utils"
import { HAPPY_LABEL, STATE_META, reached } from "@/lib/states"
import type { PaymentState } from "@/lib/types"

type Status = "done" | "current" | "failed" | "skipped"
interface Row { label: string; status: Status }

function rows(state: PaymentState): Row[] {
  const { step, branch } = reached(state)
  const terminal = STATE_META[state].terminal
  const out: Row[] = HAPPY_LABEL.map((label, i) => ({ label, status: i <= step ? "done" : i === step + 1 && !terminal ? "current" : "skipped" }))
  if (branch === "debit_stop") {
    out[1] = { label: state === "DEBIT_DECLINED" ? "Payer's bank declined the debit" : "Debit retries ran out", status: "failed" }
  }
  if (branch === "reversal") {
    out[2] = { label: "Payee's bank could not credit", status: "failed" }
    out[3] = { label: "Banks notified", status: "skipped" }
    out.push({
      label: state === "REVERSAL_FAILED" ? "Debit could not be returned" : "Debit returned to payer",
      status: state === "REVERSED" ? "done" : state === "REVERSAL_FAILED" ? "failed" : "current",
    })
  }
  return out
}

export function Lifecycle({ state }: { state: PaymentState }) {
  return (
    <ol className="space-y-3">
      {rows(state).map((r) => (
        <li key={r.label} className="flex items-center gap-3 text-sm">
          <span className={cn(
            "grid size-5 shrink-0 place-items-center rounded-full",
            r.status === "done" && "bg-primary text-primary-foreground",
            r.status === "current" && "border border-primary text-primary",
            r.status === "failed" && "bg-bad text-white",
            r.status === "skipped" && "text-muted-foreground/50",
          )}>
            {r.status === "done" && <Check className="size-3" />}
            {r.status === "current" && <Loader2 className="size-3 animate-spin" />}
            {r.status === "failed" && <X className="size-3" />}
            {r.status === "skipped" && <Circle className="size-3" />}
          </span>
          <span className={cn(r.status === "skipped" && "text-muted-foreground", r.status === "failed" && "font-medium")}>{r.label}</span>
        </li>
      ))}
    </ol>
  )
}

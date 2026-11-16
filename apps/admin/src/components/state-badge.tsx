import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import { STATE_META, type Group } from "@/lib/states"
import type { PaymentState } from "@/lib/types"

const TONE: Record<Group, string> = {
  in_flight: "bg-secondary text-foreground border-transparent",
  completed: "bg-ok/10 text-ok border-transparent",
  reversed: "bg-warn/10 text-warn border-transparent",
  declined: "bg-muted text-muted-foreground border-transparent",
  attention: "bg-bad text-white border-transparent",
}

export function StateBadge({ state }: { state: PaymentState }) {
  const m = STATE_META[state]
  return (
    <Badge variant="outline" className={cn("gap-1.5 font-medium", TONE[m.group])}>
      <span className={cn("size-1.5 rounded-full bg-current", m.group === "in_flight" && "animate-pulse")} />
      {m.label}
    </Badge>
  )
}

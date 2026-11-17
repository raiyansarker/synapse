import { useQuery } from "@tanstack/react-query"
import { createFileRoute } from "@tanstack/react-router"
import { useMemo } from "react"
import { Bar, BarChart, CartesianGrid, XAxis } from "recharts"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart"
import { Skeleton } from "@/components/ui/skeleton"
import { StateBadge } from "@/components/state-badge"
import { ago, shortId, taka } from "@/lib/format"
import { STATE_META } from "@/lib/states"
import { paymentsQuery } from "@/lib/queries"
import { useSelectPayment } from "@/hooks/use-select-payment"
import { TriangleAlert } from "lucide-react"

const HOUR = 36e5
const STUCK_MS = 2 * 60e3 // consumers retry 3 times, 3s apart; two minutes in flight is not normal

const chartConfig = {
  completed: { label: "Completed", color: "var(--chart-1)" },
  other: { label: "Declined or reversed", color: "var(--chart-3)" },
} satisfies ChartConfig

function Kpi({ label, value, hint }: { label: string; value?: string; hint: string }) {
  return (
    <Card>
      <CardHeader>
        <CardDescription>{label}</CardDescription>
        {value ? <CardTitle className="text-3xl tnum">{value}</CardTitle> : <Skeleton className="h-9 w-28" />}
        <p className="text-xs text-muted-foreground">{hint}</p>
      </CardHeader>
    </Card>
  )
}

export const Route = createFileRoute("/overview")({ component: OverviewPage })

function OverviewPage() {
  const { data: payments } = useQuery(paymentsQuery)
  const onSelect = useSelectPayment()
  const s = useMemo(() => {
    if (!payments) return undefined
    const now = Date.now()
    const day = payments.filter((p) => now - Date.parse(p.createdAt) < 24 * HOUR)
    const done = day.filter((p) => p.state === "COMPLETED")
    const settled = day.filter((p) => STATE_META[p.state].terminal)
    const inFlight = day.filter((p) => !STATE_META[p.state].terminal)
    const attention = payments.filter((p) =>
      p.state === "REVERSAL_FAILED" || (!STATE_META[p.state].terminal && now - Date.parse(p.updatedAt) > STUCK_MS))

    const buckets = Array.from({ length: 24 }, (_, i) => {
      const start = now - (24 - i) * HOUR
      const h = new Date(start + HOUR)
      return { hour: `${String(h.getHours()).padStart(2, "0")}:00`, start, completed: 0, other: 0 }
    })
    for (const p of day) {
      const b = buckets.find((x) => Date.parse(p.createdAt) >= x.start && Date.parse(p.createdAt) < x.start + HOUR)
      if (!b || !STATE_META[p.state].terminal) continue
      p.state === "COMPLETED" ? b.completed++ : b.other++
    }
    return {
      count: day.length,
      rate: settled.length ? (done.length / settled.length) * 100 : 0,
      volume: done.reduce((n, p) => n + p.amount, 0),
      inFlight: inFlight.length,
      attention,
      buckets,
    }
  }, [payments])

  const lost = s?.attention.filter((p) => p.state === "REVERSAL_FAILED") ?? []

  return (
    <div className="space-y-6">
      {lost.length > 0 && (
        <Alert variant="destructive" className="bg-card">
          <TriangleAlert />
          <AlertTitle>{lost.length === 1 ? "A payer was debited and the refund failed" : `${lost.length} payers were debited and refunds failed`}</AlertTitle>
          <AlertDescription>
            {taka(lost.reduce((n, p) => n + p.amount, 0))} is sitting between banks. The switch has stopped retrying, so these need a manual correction.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Kpi label="Payments, last 24 hours" value={s?.count.toLocaleString()} hint="Accepted by the switch" />
        <Kpi label="Success rate" value={s && `${s.rate.toFixed(1)}%`} hint="Completed of all that finished" />
        <Kpi label="Settled volume" value={s && taka(s.volume)} hint="Completed payments only" />
        <Kpi label="In flight" value={s?.inFlight.toString()} hint="Still moving through the queues" />
      </div>

      <div className="grid gap-4 xl:grid-cols-5">
        <Card className="xl:col-span-3">
          <CardHeader>
            <CardTitle>Finished payments by hour</CardTitle>
            <CardDescription>Last 24 hours, by when they were accepted</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer config={chartConfig} className="h-56 w-full">
              <BarChart data={s?.buckets ?? []} margin={{ left: 12, right: 12 }}>
                <CartesianGrid vertical={false} />
                <XAxis dataKey="hour" tickLine={false} axisLine={false} interval={3} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="completed" stackId="a" fill="var(--color-completed)" radius={[0, 0, 3, 3]} />
                <Bar dataKey="other" stackId="a" fill="var(--color-other)" radius={[3, 3, 0, 0]} />
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>

        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle>Needs attention</CardTitle>
            <CardDescription>Failed refunds, and payments stuck mid-flight for over 2 minutes</CardDescription>
          </CardHeader>
          <CardContent>
            {s && s.attention.length === 0 && <p className="py-6 text-sm text-muted-foreground">Nothing needs attention right now.</p>}
            <ul className="divide-y">
              {s?.attention.map((p) => (
                <li key={p.id}>
                  <button onClick={() => onSelect(p.id)} className="flex w-full items-center justify-between gap-3 py-3 text-left text-sm outline-none focus-visible:bg-accent">
                    <span>
                      <span className="block font-medium tnum">{taka(p.amount)} <span className="font-normal text-muted-foreground">{shortId(p.id)}</span></span>
                      <span className="text-muted-foreground">{p.sva} to {p.rva} · {ago(p.updatedAt)}</span>
                    </span>
                    <StateBadge state={p.state} />
                  </button>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

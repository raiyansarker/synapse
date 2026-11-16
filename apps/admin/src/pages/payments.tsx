import { useMemo, useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Skeleton } from "@/components/ui/skeleton"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { StateBadge } from "@/components/state-badge"
import { ago, shortId, taka } from "@/lib/format"
import { GROUP_LABEL, STATE_META, type Group } from "@/lib/states"
import type { Payment } from "@/lib/types"

const PAGE = 25

export function PaymentsPage({ payments, onSelect }: { payments?: Payment[]; onSelect: (id: string) => void }) {
  const [q, setQ] = useState("")
  const [group, setGroup] = useState<"all" | Group>("all")
  const [limit, setLimit] = useState(PAGE)

  const rows = useMemo(() => {
    const term = q.trim().toLowerCase()
    return (payments ?? []).filter((p) =>
      (group === "all" || STATE_META[p.state].group === group) &&
      (!term || p.id.includes(term) || p.sva.includes(term) || p.rva.includes(term)),
    )
  }, [payments, q, group])

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <Input className="max-w-xs bg-card" placeholder="Search id or address" value={q} onChange={(e) => { setQ(e.target.value); setLimit(PAGE) }} />
        <Select value={group} onValueChange={(v) => { setGroup(v as "all" | Group); setLimit(PAGE) }}>
          <SelectTrigger className="w-44 bg-card"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All outcomes</SelectItem>
            {(Object.keys(GROUP_LABEL) as Group[]).map((g) => <SelectItem key={g} value={g}>{GROUP_LABEL[g]}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      <Card className="py-0">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-6">Payment</TableHead>
                <TableHead>Payer</TableHead>
                <TableHead>Payee</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>State</TableHead>
                <TableHead className="pr-6 text-right">Updated</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {!payments && Array.from({ length: 6 }, (_, i) => (
                <TableRow key={i}><TableCell colSpan={6} className="px-6"><Skeleton className="h-5 w-full" /></TableCell></TableRow>
              ))}
              {payments && rows.length === 0 && (
                <TableRow><TableCell colSpan={6} className="h-32 text-center text-muted-foreground">No payments match these filters.</TableCell></TableRow>
              )}
              {rows.slice(0, limit).map((p) => (
                <TableRow key={p.id} className="cursor-pointer" onClick={() => onSelect(p.id)}>
                  <TableCell className="pl-6 font-medium tnum">{shortId(p.id)}</TableCell>
                  <TableCell>{p.sva}</TableCell>
                  <TableCell>{p.rva}</TableCell>
                  <TableCell className="text-right tnum">{taka(p.amount)}</TableCell>
                  <TableCell><StateBadge state={p.state} /></TableCell>
                  <TableCell className="pr-6 text-right text-muted-foreground">{ago(p.updatedAt)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {rows.length > limit && (
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>Showing {limit} of {rows.length}</span>
          <Button variant="outline" size="sm" onClick={() => setLimit(limit + PAGE)}>Show 25 more</Button>
        </div>
      )}
    </div>
  )
}

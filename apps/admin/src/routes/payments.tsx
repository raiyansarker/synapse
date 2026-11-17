import { useQuery } from "@tanstack/react-query"
import { createFileRoute, useNavigate } from "@tanstack/react-router"
import {
  createColumnHelper, flexRender, getCoreRowModel, getFilteredRowModel, getPaginationRowModel, getSortedRowModel,
  useReactTable, type SortingState,
} from "@tanstack/react-table"
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react"
import { useEffect, useMemo, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Skeleton } from "@/components/ui/skeleton"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { StateBadge } from "@/components/state-badge"
import { useSelectPayment } from "@/hooks/use-select-payment"
import { ago, shortId, taka } from "@/lib/format"
import { paymentsQuery } from "@/lib/queries"
import { ALL_STATES, GROUP_LABEL, STATE_META, type Group } from "@/lib/states"
import type { Payment } from "@/lib/types"

type Outcome = "all" | Group

export const Route = createFileRoute("/payments")({
  // Filters live in the URL, so a filtered view can be linked and survives a reload.
  validateSearch: (s: Record<string, unknown>): { q?: string; outcome?: Outcome } => ({
    q: typeof s.q === "string" && s.q ? s.q : undefined,
    outcome: typeof s.outcome === "string" && s.outcome in GROUP_LABEL ? (s.outcome as Group) : undefined,
  }),
  component: PaymentsPage,
})

const col = createColumnHelper<Payment>()
const columns = [
  col.accessor("id", { header: "Payment", enableSorting: false, cell: (c) => <span className="font-medium tnum">{shortId(c.getValue())}</span> }),
  col.accessor("sva", { header: "Payer", enableSorting: false }),
  col.accessor("rva", { header: "Payee", enableSorting: false }),
  col.accessor("amount", { header: "Amount", cell: (c) => <span className="tnum">{taka(c.getValue())}</span> }),
  col.accessor("state", {
    header: "State",
    cell: (c) => <StateBadge state={c.getValue()} />,
    sortingFn: (a, b, id) => ALL_STATES.indexOf(a.getValue(id)) - ALL_STATES.indexOf(b.getValue(id)),
    filterFn: (row, id, group: Group) => STATE_META[row.getValue<Payment["state"]>(id)].group === group,
  }),
  col.accessor("updatedAt", { header: "Updated", cell: (c) => <span className="text-muted-foreground">{ago(c.getValue())}</span> }),
]
const RIGHT = new Set(["amount", "updatedAt"])

function PaymentsPage() {
  const { q, outcome = "all" } = Route.useSearch()
  const navigate = useNavigate({ from: "/payments" })
  const select = useSelectPayment()
  const { data: payments } = useQuery(paymentsQuery)
  const [sorting, setSorting] = useState<SortingState>([])

  const data = useMemo(() => [...(payments ?? [])].sort((a, b) => b.createdAt.localeCompare(a.createdAt)), [payments])

  const table = useReactTable({
    data,
    columns,
    state: { sorting, globalFilter: q ?? "", columnFilters: outcome === "all" ? [] : [{ id: "state", value: outcome }] },
    onSortingChange: setSorting,
    globalFilterFn: (row, _id, v: string) => {
      const t = v.trim().toLowerCase()
      const p = row.original
      return p.id.includes(t) || p.sva.includes(t) || p.rva.includes(t)
    },
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageSize: 25 } },
    autoResetPageIndex: false, // the list refreshes every 2s; do not bounce back to page 1
  })

  const { setPageIndex } = table
  useEffect(() => setPageIndex(0), [q, outcome, setPageIndex])

  const rows = table.getRowModel().rows
  const { pageIndex, pageSize } = table.getState().pagination
  const total = table.getFilteredRowModel().rows.length

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <Input className="max-w-xs bg-card" placeholder="Search id or address" value={q ?? ""}
          onChange={(e) => navigate({ search: (prev) => ({ ...prev, q: e.target.value || undefined }), replace: true })} />
        <Select value={outcome} onValueChange={(v) => navigate({ search: (prev) => ({ ...prev, outcome: v === "all" ? undefined : (v as Group) }) })}>
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
              {table.getHeaderGroups().map((hg) => (
                <TableRow key={hg.id}>
                  {hg.headers.map((h, i) => {
                    const sorted = h.column.getIsSorted()
                    const right = RIGHT.has(h.column.id)
                    return (
                      <TableHead key={h.id} className={`${i === 0 ? "pl-6" : ""} ${i === hg.headers.length - 1 ? "pr-6" : ""} ${right ? "text-right" : ""}`}
                        aria-sort={sorted === "asc" ? "ascending" : sorted === "desc" ? "descending" : undefined}>
                        {h.column.getCanSort() ? (
                          <Button variant="ghost" size="sm" className={`-mx-3 h-8 ${right ? "flex-row-reverse" : ""}`} onClick={h.column.getToggleSortingHandler()}>
                            {flexRender(h.column.columnDef.header, h.getContext())}
                            {sorted === "asc" ? <ArrowUp /> : sorted === "desc" ? <ArrowDown /> : <ArrowUpDown className="opacity-40" />}
                          </Button>
                        ) : flexRender(h.column.columnDef.header, h.getContext())}
                      </TableHead>
                    )
                  })}
                </TableRow>
              ))}
            </TableHeader>
            <TableBody>
              {!payments && Array.from({ length: 6 }, (_, i) => (
                <TableRow key={i}><TableCell colSpan={columns.length} className="px-6"><Skeleton className="h-5 w-full" /></TableCell></TableRow>
              ))}
              {payments && rows.length === 0 && (
                <TableRow><TableCell colSpan={columns.length} className="h-32 text-center text-muted-foreground">No payments match these filters.</TableCell></TableRow>
              )}
              {rows.map((row) => (
                <TableRow key={row.id} className="cursor-pointer" onClick={() => select(row.original.id)}>
                  {row.getVisibleCells().map((cell, i) => (
                    <TableCell key={cell.id} className={`${i === 0 ? "pl-6" : ""} ${i === row.getVisibleCells().length - 1 ? "pr-6" : ""} ${RIGHT.has(cell.column.id) ? "text-right" : ""}`}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {total > pageSize && (
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span className="tnum">{pageIndex * pageSize + 1} to {Math.min((pageIndex + 1) * pageSize, total)} of {total}</span>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => table.previousPage()} disabled={!table.getCanPreviousPage()}>Previous</Button>
            <Button variant="outline" size="sm" onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}>Next</Button>
          </div>
        </div>
      )}
    </div>
  )
}

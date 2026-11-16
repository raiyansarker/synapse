import { useState } from "react"
import { ArrowLeftRight, LayoutDashboard, Moon, Plus, Sun } from "lucide-react"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import {
  Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent, SidebarHeader,
  SidebarInset, SidebarMenu, SidebarMenuButton, SidebarMenuItem, SidebarProvider, SidebarTrigger,
} from "@/components/ui/sidebar"
import { Toaster } from "@/components/ui/sonner"
import { NewPaymentDialog } from "@/components/new-payment-dialog"
import { PaymentSheet } from "@/components/payment-sheet"
import { useHashRoute, type Route } from "@/hooks/use-hash-route"
import { usePoll } from "@/hooks/use-poll"
import { useTheme } from "@/hooks/use-theme"
import { api, MODE } from "@/lib/api"
import { OverviewPage } from "@/pages/overview"
import { PaymentsPage } from "@/pages/payments"

const NAV: { route: Route; label: string; icon: typeof LayoutDashboard }[] = [
  { route: "overview", label: "Overview", icon: LayoutDashboard },
  { route: "payments", label: "Payments", icon: ArrowLeftRight },
]

export default function App() {
  const [route, go] = useHashRoute()
  const [theme, toggleTheme] = useTheme()
  const [selected, setSelected] = useState<string>()
  const [newPayment, setNewPayment] = useState(false)

  const payments = usePoll(() => api.listPayments())
  const error = payments.error
  const title = NAV.find((n) => n.route === route)!.label

  return (
    <SidebarProvider>
      <Sidebar>
        <SidebarHeader className="px-4 py-5">
          <div className="text-lg font-semibold tracking-tight">Synapse</div>
          <div className="text-xs text-muted-foreground">Bank administration</div>
        </SidebarHeader>
        <SidebarContent>
          <SidebarGroup>
            <SidebarGroupContent>
              <SidebarMenu>
                {NAV.map(({ route: r, label, icon: Icon }) => (
                  <SidebarMenuItem key={r}>
                    <SidebarMenuButton isActive={route === r} onClick={() => go(r)}><Icon /> {label}</SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>
        <SidebarFooter className="p-4">
          <Badge variant="outline" className="w-fit">{MODE === "mock" ? "Sample data" : "Live switch"}</Badge>
        </SidebarFooter>
      </Sidebar>

      <SidebarInset>
        <header className="flex h-14 items-center gap-3 border-b bg-card px-4">
          <SidebarTrigger />
          <Separator orientation="vertical" className="h-5" />
          <h1 className="text-base font-semibold">{title}</h1>
          <div className="ml-auto flex items-center gap-2">
            <Button variant="ghost" size="icon" onClick={toggleTheme} aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}>
              {theme === "dark" ? <Sun /> : <Moon />}
            </Button>
            <Button size="sm" onClick={() => setNewPayment(true)}><Plus /> New payment</Button>
          </div>
        </header>

        <main className="mx-auto w-full max-w-6xl space-y-4 p-4 md:p-6">
          {error && (
            <Alert variant="destructive" className="bg-card">
              <AlertTitle>{error.message.split(": ")[0]}</AlertTitle>
              <AlertDescription>{error.message.split(": ").slice(1).join(": ") || "Showing the last data received."}</AlertDescription>
            </Alert>
          )}
          {route === "overview" && <OverviewPage payments={payments.data} onSelect={setSelected} />}
          {route === "payments" && <PaymentsPage payments={payments.data} onSelect={setSelected} />}
        </main>
      </SidebarInset>

      <PaymentSheet payment={payments.data?.find((p) => p.id === selected)} onClose={() => setSelected(undefined)} />
      <NewPaymentDialog open={newPayment} onOpenChange={setNewPayment} onCreated={() => { payments.refresh(); go("payments") }} />
      <Toaster theme={theme} />
    </SidebarProvider>
  )
}

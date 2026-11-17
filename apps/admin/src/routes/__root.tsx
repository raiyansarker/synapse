/// <reference types="vite/client" />
import type { QueryClient } from "@tanstack/react-query"
import { useQuery } from "@tanstack/react-query"
import { HeadContent, Link, Outlet, Scripts, createRootRouteWithContext, useRouterState } from "@tanstack/react-router"
import { ArrowLeftRight, LayoutDashboard, Moon, Plus, Sun } from "lucide-react"
import { useState, type ReactNode } from "react"
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
import { useSelectPayment } from "@/hooks/use-select-payment"
import { useTheme } from "@/hooks/use-theme"
import { parseError } from "@/lib/errors"
import { modeQuery, paymentsQuery } from "@/lib/queries"
import appCss from "@/index.css?url"

// Runs before first paint so dark users never see a light flash.
const THEME_SCRIPT = `try{var t=localStorage.getItem("theme");if(t==="dark"||(!t&&matchMedia("(prefers-color-scheme: dark)").matches))document.documentElement.classList.add("dark")}catch(e){}`

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [{ charSet: "utf-8" }, { name: "viewport", content: "width=device-width, initial-scale=1" }, { title: "Synapse Admin" }],
    links: [{ rel: "stylesheet", href: appCss }],
    scripts: [{ children: THEME_SCRIPT }],
  }),
  // ?payment=<id> opens the payment sheet from any page.
  validateSearch: (s: Record<string, unknown>): { payment?: string } => ({ payment: typeof s.payment === "string" ? s.payment : undefined }),
  shellComponent: RootDocument,
  component: AppShell,
})

function RootDocument({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head><HeadContent /></head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}

const NAV = [
  { to: "/overview", label: "Overview", icon: LayoutDashboard },
  { to: "/payments", label: "Payments", icon: ArrowLeftRight },
] as const

function AppShell() {
  const { payment: selected } = Route.useSearch()
  const select = useSelectPayment()
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  const [theme, toggleTheme] = useTheme()
  const [newPayment, setNewPayment] = useState(false)

  const payments = useQuery(paymentsQuery)
  const mode = useQuery(modeQuery)
  const error = payments.error ? parseError(payments.error) : undefined
  const title = NAV.find((n) => pathname.startsWith(n.to))?.label ?? "Synapse"

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
                {NAV.map(({ to, label, icon: Icon }) => (
                  <SidebarMenuItem key={to}>
                    <SidebarMenuButton asChild isActive={pathname.startsWith(to)}>
                      <Link to={to}><Icon /> {label}</Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>
        <SidebarFooter className="p-4">
          {mode.data && <Badge variant="outline" className="w-fit">{mode.data === "mock" ? "Sample data" : "Live switch"}</Badge>}
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
              <AlertTitle>{error.title}</AlertTitle>
              <AlertDescription>{error.detail}</AlertDescription>
            </Alert>
          )}
          <Outlet />
        </main>
      </SidebarInset>

      <PaymentSheet payment={payments.data?.find((p) => p.id === selected)} onClose={() => select(undefined)} />
      <NewPaymentDialog open={newPayment} onOpenChange={setNewPayment} />
      <Toaster theme={theme} />
    </SidebarProvider>
  )
}

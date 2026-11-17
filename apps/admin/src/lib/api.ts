import { createServerFn } from "@tanstack/react-start"
import type { NewPayment } from "./types"

// Everything here runs on the dashboard's server. The browser calls these as RPCs and never talks to the switch.
// The backend is imported inside each handler so the mock and the switch client stay out of the browser bundle.

export const getMode = createServerFn({ method: "GET" }).handler(async () => (await import("@/server/backend.server")).mode)

export const listPayments = createServerFn({ method: "GET" }).handler(async () => (await import("@/server/backend.server")).backend.listPayments())

export const getPaymentState = createServerFn({ method: "GET" })
  .validator((id: string) => id)
  .handler(async ({ data }) => (await import("@/server/backend.server")).backend.getPaymentState(data))

export const createPayment = createServerFn({ method: "POST" })
  .validator((p: NewPayment) => p)
  .handler(async ({ data }) => (await import("@/server/backend.server")).backend.createPayment(data))

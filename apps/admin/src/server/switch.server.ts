import type { Backend } from "./backend.server"
import type { Payment, PaymentState } from "@/lib/types"

/** libs/common wraps every response, success or failure, in this shape. */
interface Envelope<T> {
  success: boolean
  data?: T
  error?: { title: string; detail: string }
}

async function call<T>(path: string, init?: RequestInit): Promise<T> {
  const base = process.env.SWITCH_URL ?? "http://localhost:8080"
  const res = await fetch(base + path, {
    ...init,
    headers: { "Content-Type": "application/json", "X-Request-Id": crypto.randomUUID(), ...init?.headers },
  }).catch(() => {
    throw new Error(`Switch unreachable: Could not reach ${base}. Check that the switch is running and SWITCH_URL is right.`)
  })
  const body = (await res.json().catch(() => null)) as Envelope<T> | null
  if (!res.ok || !body?.success) {
    throw new Error(`${body?.error?.title ?? `HTTP ${res.status}`}: ${body?.error?.detail ?? "The switch returned an unexpected response."}`)
  }
  return body.data as T
}

/** The first two routes exist on the switch today (Pay.java). The list route is the one it still needs; see README. */
export const switchBackend: Backend = {
  getPaymentState: async (id) => (await call<{ state: PaymentState }>(`/api/pay/${encodeURIComponent(id)}`)).state,
  createPayment: async (p) => (await call<{ idempotencyKey: string }>("/api/pay", { method: "POST", body: JSON.stringify(p) })).idempotencyKey,
  listPayments: () => call<Payment[]>("/api/admin/payments"),
}

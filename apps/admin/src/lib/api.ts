import { mockApi } from "./mock"
import type { NewPayment, Payment, PaymentState } from "./types"

/** libs/common wraps every response, success or failure, in this shape. */
interface Envelope<T> {
  success: boolean
  data?: T
  error?: { title: string; detail: string; reasons?: Record<string, string>[] }
  meta?: { requestId: string; timestamp: string }
}

export class ApiError extends Error {
  constructor(public title: string, public detail: string, public status: number, public requestId?: string) {
    super(`${title}: ${detail}`)
  }
}

async function call<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { "Content-Type": "application/json", "X-Request-Id": crypto.randomUUID(), ...init?.headers },
  }).catch(() => {
    throw new ApiError("Switch unreachable", "Check that the switch is running and VITE_SWITCH_URL is right.", 0)
  })
  const body = (await res.json().catch(() => null)) as Envelope<T> | null
  if (!res.ok || !body?.success) {
    throw new ApiError(
      body?.error?.title ?? `HTTP ${res.status}`,
      body?.error?.detail ?? "The switch returned an unexpected response.",
      res.status,
      body?.meta?.requestId,
    )
  }
  return body.data as T
}

export interface Api {
  listPayments(): Promise<Payment[]>
  getPaymentState(id: string): Promise<PaymentState>
  createPayment(p: NewPayment): Promise<string>
}

/**
 * Live mode. The first two calls hit routes the switch has today (Pay.java).
 * The rest are the admin routes the switch still needs; see README.md for the contract.
 */
const liveApi: Api = {
  getPaymentState: async (id) => (await call<{ state: PaymentState }>(`/api/pay/${encodeURIComponent(id)}`)).state,
  createPayment: async (p) => (await call<{ idempotencyKey: string }>("/api/pay", { method: "POST", body: JSON.stringify(p) })).idempotencyKey,
  listPayments: () => call<Payment[]>("/api/admin/payments"),
}

export const MODE = import.meta.env.VITE_API_MODE === "live" ? "live" : "mock"
export const api: Api = MODE === "live" ? liveApi : mockApi

import type { NewPayment, Payment, PaymentState } from "@/lib/types"
import { mockBackend } from "./mock.server"
import { switchBackend } from "./switch.server"

export interface Backend {
  listPayments(): Promise<Payment[]>
  getPaymentState(id: string): Promise<PaymentState>
  createPayment(p: NewPayment): Promise<string>
}

export const mode: "mock" | "live" = process.env.API_MODE === "live" ? "live" : "mock"
export const backend: Backend = mode === "live" ? switchBackend : mockBackend

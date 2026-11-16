export type PaymentState =
  | "ACCEPTED"
  | "DEBIT_AUTHORIZATION_PENDING"
  | "DEBIT_AUTHORIZED"
  | "DEBIT_DECLINED"
  | "DEBIT_AUTHORIZATION_FAILED"
  | "CREDIT_AUTHORIZATION_PENDING"
  | "CREDIT_AUTHORIZED"
  | "ACKNOWLEDGING"
  | "COMPLETED"
  | "REVERSAL_PENDING"
  | "REVERSED"
  | "REVERSAL_FAILED"

/** Mirrors synapse.upi.ledger.Ledger. */
export interface Payment {
  id: string
  sva: string
  rva: string
  amount: number
  state: PaymentState
  createdAt: string
  updatedAt: string
}

export interface NewPayment {
  sva: string
  rva: string
  amount: number
}

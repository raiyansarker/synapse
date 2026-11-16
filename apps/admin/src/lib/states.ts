import type { PaymentState } from "./types"

export type Group = "in_flight" | "completed" | "reversed" | "declined" | "attention"

export const STATE_META: Record<PaymentState, { label: string; group: Group; terminal: boolean; note: string }> = {
  ACCEPTED: { label: "Accepted", group: "in_flight", terminal: false, note: "Stored in the ledger and queued for debit." },
  DEBIT_AUTHORIZATION_PENDING: { label: "Debiting", group: "in_flight", terminal: false, note: "Waiting on the payer's bank to authorize the debit." },
  DEBIT_AUTHORIZED: { label: "Debited", group: "in_flight", terminal: false, note: "Payer's bank approved. Money has left the payer." },
  DEBIT_DECLINED: { label: "Debit declined", group: "declined", terminal: true, note: "Payer's bank refused. No money moved." },
  DEBIT_AUTHORIZATION_FAILED: { label: "Debit failed", group: "declined", terminal: true, note: "Debit retries ran out. No money moved." },
  CREDIT_AUTHORIZATION_PENDING: { label: "Crediting", group: "in_flight", terminal: false, note: "Waiting on the payee's bank to authorize the credit." },
  CREDIT_AUTHORIZED: { label: "Credited", group: "in_flight", terminal: false, note: "Payee's bank approved. Ready to notify both banks." },
  ACKNOWLEDGING: { label: "Notifying", group: "in_flight", terminal: false, note: "Telling both banks the payment went through." },
  COMPLETED: { label: "Completed", group: "completed", terminal: true, note: "Money moved and both banks were told." },
  REVERSAL_PENDING: { label: "Reversing", group: "in_flight", terminal: false, note: "Credit failed. The debit is being returned to the payer." },
  REVERSED: { label: "Reversed", group: "reversed", terminal: true, note: "Debit returned to the payer. Net movement is zero." },
  REVERSAL_FAILED: { label: "Reversal failed", group: "attention", terminal: true, note: "Payer was debited, payee was not credited, and the refund failed. Fix by hand." },
}

export const GROUP_LABEL: Record<Group, string> = {
  in_flight: "In flight",
  completed: "Completed",
  reversed: "Reversed",
  declined: "Declined",
  attention: "Needs attention",
}

export const ALL_STATES = Object.keys(STATE_META) as PaymentState[]

/** The ledger keeps only the latest state, so earlier steps are inferred from it. */
export const HAPPY: PaymentState[] = ["ACCEPTED", "DEBIT_AUTHORIZED", "CREDIT_AUTHORIZED", "COMPLETED"]
export const HAPPY_LABEL = ["Accepted", "Debited from payer", "Credited to payee", "Banks notified"]

export function reached(state: PaymentState): { step: number; branch: "none" | "debit_stop" | "reversal" } {
  switch (state) {
    case "ACCEPTED": case "DEBIT_AUTHORIZATION_PENDING": return { step: 0, branch: "none" }
    case "DEBIT_DECLINED": case "DEBIT_AUTHORIZATION_FAILED": return { step: 0, branch: "debit_stop" }
    case "DEBIT_AUTHORIZED": case "CREDIT_AUTHORIZATION_PENDING": return { step: 1, branch: "none" }
    case "CREDIT_AUTHORIZED": case "ACKNOWLEDGING": return { step: 2, branch: "none" }
    case "COMPLETED": return { step: 3, branch: "none" }
    default: return { step: 1, branch: "reversal" }
  }
}

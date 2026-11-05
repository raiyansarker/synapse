package synapse.upi.payment.statemachine;

/**
 * Facts that move a payment. The switch applies an event only after the step it names has happened.
 * See docs/payment-state-machine.md.
 */
public enum PaymentEvent {
  VPA_RESOLVED,
  VPA_UNRESOLVED,
  DEBIT_APPROVED,
  DEBIT_DECLINED,
  CREDIT_REQUESTED,
  CREDIT_APPROVED,
  CREDIT_REJECTED,
  PAYER_ACKNOWLEDGED,
  PAYER_ACK_FAILED,
  REVERSAL_APPROVED,
  REVERSAL_REJECTED
}

package synapse.upi.payment.statemachine;

/**
 * Where a payment sits on the switch. Terminal states are Spring Statemachine end states. See
 * docs/payment-state-machine.md.
 */
public enum PaymentState {
  ACCEPTED(false),
  AUTHORIZATION_PENDING(false),
  AUTHORIZED(false),
  CREDIT_PENDING(false),
  ACKNOWLEDGING(false),
  COMPLETED(true),
  RESOLUTION_FAILED(true),
  DECLINED(true),
  REVERSAL_PENDING(false),
  REVERSED(true),
  REVERSAL_FAILED(true);

  private final boolean terminal;

  PaymentState(boolean terminal) {
    this.terminal = terminal;
  }

  public boolean terminal() {
    return terminal;
  }
}

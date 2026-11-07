package synapse.upi.ledger;

/**
 * Where a payment sits on the switch. Terminal states end the lifecycle.
 *
 * <p>{@code ACCEPTED} → resolve VPAs → authorize debit → credit payee → acknowledge payer, or
 * reverse the debit if credit / ack fails.
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

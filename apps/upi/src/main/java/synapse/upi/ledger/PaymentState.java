package synapse.upi.ledger;

/**
 * Where a payment sits on the switch. Terminal states end the lifecycle.
 *
 * <p>{@code ACCEPTED}
 * → {@code DEBIT_AUTHORIZATION_PENDING}
 * → {@code DEBIT_AUTHORIZED} | {@code DEBIT_DECLINED} | {@code DEBIT_AUTHORIZATION_FAILED}
 * → {@code CREDIT_AUTHORIZATION_PENDING}
 * → {@code CREDIT_AUTHORIZED} | {@code REVERSAL_PENDING}
 * → {@code ACKNOWLEDGING}
 * → {@code COMPLETED} | {@code REVERSAL_PENDING}
 * → {@code REVERSED} | {@code REVERSAL_FAILED}
 */
public enum PaymentState {
  ACCEPTED(false),

  DEBIT_AUTHORIZATION_PENDING(false),
  DEBIT_AUTHORIZED(false),
  DEBIT_DECLINED(true),
  DEBIT_AUTHORIZATION_FAILED(true),

  CREDIT_AUTHORIZATION_PENDING(false),
  CREDIT_AUTHORIZED(false),
  CREDIT_AUTHORIZATION_FAILED(true),

  ACKNOWLEDGING(false),
  COMPLETED(true),

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

  /** Eligible for the debit-authorization consumer. */
  public boolean awaitingDebitAuthorization() {
    return this == ACCEPTED || this == DEBIT_AUTHORIZATION_PENDING;
  }

  /** Eligible for the credit-authorization consumer. */
  public boolean awaitingCreditAuthorization() {
    return this == DEBIT_AUTHORIZED || this == CREDIT_AUTHORIZATION_PENDING;
  }
}

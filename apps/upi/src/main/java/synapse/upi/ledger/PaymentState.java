package synapse.upi.ledger;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * Where a payment sits on the switch. Terminal states end the lifecycle.
 *
 * <p>{@code ACCEPTED}
 * → {@code DEBIT_AUTHORIZATION_PENDING}
 * → {@code DEBIT_AUTHORIZED} | {@code DEBIT_DECLINED} | {@code DEBIT_AUTHORIZATION_FAILED}
 * → {@code CREDIT_AUTHORIZATION_PENDING}
 * → {@code CREDIT_AUTHORIZED} | {@code REVERSAL_PENDING} (credit decline / exhaust)
 * → {@code ACKNOWLEDGING}
 * → {@code COMPLETED} | {@code REVERSAL_PENDING} (ack fail / exhaust)
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

  /** Eligible for the acknowledgment / notify consumer. */
  public boolean awaitingAcknowledgment() {
    return this == CREDIT_AUTHORIZED || this == ACKNOWLEDGING;
  }

  /** Eligible for the reversal consumer. */
  public boolean awaitingReversal() {
    return this == REVERSAL_PENDING;
  }

  /**
   * Persist as plain {@code varchar} so Hibernate does not emit an enum {@code CHECK}
   * that {@code ddl-auto: update} fails to refresh.
   */
  @Converter(autoApply = true)
  static class AsString implements AttributeConverter<PaymentState, String> {
    @Override
    public String convertToDatabaseColumn(PaymentState state) {
      return state == null ? null : state.name();
    }

    @Override
    public PaymentState convertToEntityAttribute(String value) {
      return value == null ? null : PaymentState.valueOf(value);
    }
  }
}

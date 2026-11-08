package synapse.upi.pay.credit.interfaces;

/**
 * Business outcome of a credit authorization attempt.
 *
 * <p>Transient failures must be thrown so {@code @RetryQueue} can retry.
 */
public sealed interface CreditResult {

  record Approved() implements CreditResult {}

  record Declined(String reasonCode) implements CreditResult {}
}

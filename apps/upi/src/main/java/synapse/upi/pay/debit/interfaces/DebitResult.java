package synapse.upi.pay.debit.interfaces;

/**
 * Business outcome of a debit authorization attempt.
 *
 * <p>Transient failures (timeout, network, 5xx) must be thrown so {@code @RetryQueue} can retry.
 */
public sealed interface DebitResult {

  record Approved() implements DebitResult {}

  record Declined(String reasonCode) implements DebitResult {}
}

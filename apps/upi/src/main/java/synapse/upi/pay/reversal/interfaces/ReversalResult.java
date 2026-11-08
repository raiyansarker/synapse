package synapse.upi.pay.reversal.interfaces;

/**
 * Business outcome of reversing a prior debit at the sender bank.
 *
 * <p>Transient failures must be thrown so {@code @RetryQueue} can retry.
 */
public sealed interface ReversalResult {

  record Reversed() implements ReversalResult {}

  record Failed(String reasonCode) implements ReversalResult {}
}

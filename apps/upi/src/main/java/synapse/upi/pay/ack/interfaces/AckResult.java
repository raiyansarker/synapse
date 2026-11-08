package synapse.upi.pay.ack.interfaces;

/**
 * Business outcome of notifying banks that settlement succeeded.
 *
 * <p>Transient failures must be thrown so {@code @RetryQueue} can retry.
 */
public sealed interface AckResult {

  record Succeeded() implements AckResult {}

  record Failed(String reasonCode) implements AckResult {}
}

package synapse.upi.queue.retry;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import synapse.upi.ledger.PaymentState;

/**
 * Class-level annotation for consumers that enables automatic native delivery delay retries
 * and dead-letter / follow-up queue routing.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RetryQueue {
  int maxAttempts() default 3;
  long delayMillis() default 3000L;
  String routingKey();
  /** Ledger state applied when retries are exhausted. */
  PaymentState exhaustedState();
  /**
   * Optional follow-up routing key after exhaustion (e.g. reversal after credit/ack failure).
   * Empty means dead-letter queue.
   */
  String exhaustedRoutingKey() default "";
}

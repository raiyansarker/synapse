package synapse.upi.queue.retry;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import synapse.upi.ledger.PaymentState;

/**
 * Class-level annotation for consumers that enables automatic native delivery delay retries
 * and dead-letter queue routing.
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
}

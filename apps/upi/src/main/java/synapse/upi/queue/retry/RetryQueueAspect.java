package synapse.upi.queue.retry;

import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.aop.support.AopUtils;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.queue.message.AcceptedPay;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Aspect
@Component
public class RetryQueueAspect {

  public static final String RETRY_COUNT_HEADER = "x-retry-count";
  public static final String DELIVERY_TIME_HEADER = "x-opt-delivery-time";

  private final RabbitTemplate rabbit;
  private final LedgerRepository ledger;
  private final TransactionTemplate transactionTemplate;

  public RetryQueueAspect(
      RabbitTemplate rabbit,
      LedgerRepository ledger,
      PlatformTransactionManager transactionManager
  ) {
    this.rabbit = rabbit;
    this.ledger = ledger;
    this.transactionTemplate = new TransactionTemplate(transactionManager);
  }

  @Around("execution(* synapse.upi.queue.consumer.Consumer.consume(..))")
  public Object handleRetry(ProceedingJoinPoint joinPoint) throws Throwable {
    Class<?> targetClass = AopUtils.getTargetClass(joinPoint.getTarget());
    RetryQueue retryConfig = AnnotationUtils.findAnnotation(targetClass, RetryQueue.class);

    if (retryConfig == null) {
      return joinPoint.proceed();
    }

    Object[] args = joinPoint.getArgs();
    if (args.length == 0 || !(args[0] instanceof AcceptedPay pay)) {
      return joinPoint.proceed();
    }

    Map<String, Object> headers = extractHeaders();
    int attempt = getAttemptCount(headers);
    int maxAttempts = retryConfig.maxAttempts();
    long delayMillis = retryConfig.delayMillis();
    String routingKey = retryConfig.routingKey();

    log.info("Consumer processing transaction id={} on key={} (attempt {}/{})",
        pay.id(), routingKey, attempt, maxAttempts);

    try {
      return joinPoint.proceed();
    } catch (DataIntegrityViolationException ex) {
      // Permanent schema/data errors must not delay-retry or the queue storms.
      throw ex;
    } catch (Exception ex) {
      if (attempt < maxAttempts) {
        long deliverAt = System.currentTimeMillis() + delayMillis;
        log.warn("Attempt {} failed for id={}: {}. Retrying via native quorum delay at epoch {}",
            attempt, pay.id(), ex.getMessage(), deliverAt);

        rabbit.convertAndSend(
            PayTopology.EXCHANGE,
            routingKey,
            pay,
            message -> {
              message.getMessageProperties().setHeader(RETRY_COUNT_HEADER, attempt + 1);
              message.getMessageProperties().setHeader(DELIVERY_TIME_HEADER, deliverAt);
              return message;
            }
        );
      } else {
        PaymentState exhaustedState = retryConfig.exhaustedState();
        log.error("Retries exhausted ({}/{}) for id={}. Marking {} and routing to dead-letter queue.",
            attempt, maxAttempts, pay.id(), exhaustedState);
        transactionTemplate.executeWithoutResult(status ->
            ledger.findById(pay.id()).ifPresent(entry -> entry.transitionTo(exhaustedState))
        );
        rabbit.convertAndSend(PayTopology.EXCHANGE, PayTopology.DEAD_LETTER_ROUTING_KEY, pay);
      }
      return null;
    } finally {
      MessageContextHolder.clear();
    }
  }

  private Map<String, Object> extractHeaders() {
    Message amqpMessage = MessageContextHolder.getCurrentMessage();
    if (amqpMessage != null && amqpMessage.getMessageProperties() != null) {
      return amqpMessage.getMessageProperties().getHeaders();
    }
    return Map.of();
  }

  private int getAttemptCount(Map<String, Object> headers) {
    if (headers == null || !headers.containsKey(RETRY_COUNT_HEADER)) {
      return 1;
    }
    Object val = headers.get(RETRY_COUNT_HEADER);
    if (val instanceof Number num) {
      return num.intValue();
    }
    return 1;
  }
}

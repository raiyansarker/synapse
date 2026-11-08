package synapse.upi.queue.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.credit.interfaces.CreditGateway;
import synapse.upi.pay.credit.interfaces.CreditResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;
import synapse.upi.queue.retry.RetryQueue;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Service
@RequiredArgsConstructor
@RetryQueue(
    routingKey = PayTopology.CREDIT_AUTHORIZATION_ROUTING_KEY,
    maxAttempts = 3,
    delayMillis = 3000L,
    exhaustedState = PaymentState.REVERSAL_PENDING,
    exhaustedRoutingKey = PayTopology.REVERSAL_ROUTING_KEY
)
public class CreditAuthorizationConsumer implements Consumer<PayId> {

  private final LedgerRepository ledger;
  private final CreditGateway creditGateway;
  private final PayProducer producer;

  @Override
  @Transactional
  @RabbitListener(queues = PayTopology.CREDIT_AUTHORIZATION_QUEUE)
  public void consume(PayId payId) {
    Ledger entry = ledger.findById(payId.id())
        .orElseThrow(() -> new IllegalStateException("Ledger entry not found: " + payId.id()));

    if (!entry.getState().awaitingCreditAuthorization()) {
      log.info("Skipping credit authorization for id={} state={}", payId.id(), entry.getState());
      return;
    }

    entry.markCreditAuthorizationPending();

    switch (creditGateway.credit(entry)) {
      case CreditResult.Approved() -> {
        entry.markCreditAuthorized();
        producer.publishAcknowledgment(payId);
        log.info("Credit authorized for id={} — queued acknowledgment", payId.id());
      }
      case CreditResult.Declined(String reasonCode) -> {
        entry.markReversalPending();
        producer.publishReversal(payId);
        log.info("Credit declined for id={} reason={} — queued reversal", payId.id(), reasonCode);
      }
    }
  }
}

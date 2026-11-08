package synapse.upi.queue.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.ack.interfaces.AckGateway;
import synapse.upi.pay.ack.interfaces.AckResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;
import synapse.upi.queue.retry.RetryQueue;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Service
@RequiredArgsConstructor
@RetryQueue(
    routingKey = PayTopology.ACKNOWLEDGMENT_ROUTING_KEY,
    maxAttempts = 3,
    delayMillis = 3000L,
    exhaustedState = PaymentState.REVERSAL_PENDING,
    exhaustedRoutingKey = PayTopology.REVERSAL_ROUTING_KEY
)
public class AcknowledgmentConsumer implements Consumer<PayId> {

  private final LedgerRepository ledger;
  private final AckGateway ackGateway;
  private final PayProducer producer;

  @Override
  @Transactional
  @RabbitListener(queues = PayTopology.ACKNOWLEDGMENT_QUEUE)
  public void consume(PayId payId) {
    Ledger entry = ledger.findById(payId.id())
        .orElseThrow(() -> new IllegalStateException("Ledger entry not found: " + payId.id()));

    if (!entry.getState().awaitingAcknowledgment()) {
      log.info("Skipping acknowledgment for id={} state={}", payId.id(), entry.getState());
      return;
    }

    entry.markAcknowledging();

    switch (ackGateway.acknowledge(entry)) {
      case AckResult.Succeeded() -> {
        entry.markCompleted();
        log.info("Acknowledgment succeeded for id={} — completed", payId.id());
      }
      case AckResult.Failed(String reasonCode) -> {
        entry.markReversalPending();
        producer.publishReversal(payId);
        log.info("Acknowledgment failed for id={} reason={} — queued reversal",
            payId.id(), reasonCode);
      }
    }
  }
}

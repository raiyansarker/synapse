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
import synapse.upi.queue.retry.RetryQueue;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Service
@RequiredArgsConstructor
@RetryQueue(
    routingKey = PayTopology.ACKNOWLEDGMENT_ROUTING_KEY,
    maxAttempts = 3,
    delayMillis = 3000L,
    exhaustedState = PaymentState.COMPLETED
)
public class AcknowledgmentConsumer implements Consumer<PayId> {

  private final LedgerRepository ledger;
  private final AckGateway ackGateway;

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
      case AckResult.Succeeded() ->
          log.info("Sender notified for id={} sva={}", payId.id(), entry.getSva());
      case AckResult.Failed(String reasonCode) ->
          log.info("Sender notify failed for id={} sva={} reason={}",
              payId.id(), entry.getSva(), reasonCode);
    }
    entry.markCompleted();
  }
}

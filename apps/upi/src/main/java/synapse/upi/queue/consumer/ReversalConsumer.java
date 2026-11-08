package synapse.upi.queue.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.reversal.interfaces.ReversalGateway;
import synapse.upi.pay.reversal.interfaces.ReversalResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.retry.RetryQueue;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Service
@RequiredArgsConstructor
@RetryQueue(
    routingKey = PayTopology.REVERSAL_ROUTING_KEY,
    maxAttempts = 3,
    delayMillis = 3000L,
    exhaustedState = PaymentState.REVERSAL_FAILED
)
public class ReversalConsumer implements Consumer<PayId> {

  private final LedgerRepository ledger;
  private final ReversalGateway reversalGateway;

  @Override
  @Transactional
  @RabbitListener(queues = PayTopology.REVERSAL_QUEUE)
  public void consume(PayId payId) {
    Ledger entry = ledger.findById(payId.id())
        .orElseThrow(() -> new IllegalStateException("Ledger entry not found: " + payId.id()));

    if (!entry.getState().awaitingReversal()) {
      log.info("Skipping reversal for id={} state={}", payId.id(), entry.getState());
      return;
    }

    switch (reversalGateway.reverse(entry)) {
      case ReversalResult.Reversed() -> {
        entry.markReversed();
        log.info("Reversal succeeded for id={}", payId.id());
      }
      case ReversalResult.Failed(String reasonCode) -> {
        entry.markReversalFailed();
        log.info("Reversal failed for id={} reason={}", payId.id(), reasonCode);
      }
    }
  }
}

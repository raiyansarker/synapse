package synapse.upi.queue.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.debit.interfaces.DebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;
import synapse.upi.queue.retry.RetryQueue;
import synapse.upi.queue.topology.PayTopology;

@Slf4j
@Service
@RequiredArgsConstructor
@RetryQueue(
    routingKey = PayTopology.DEBIT_AUTHORIZATION_ROUTING_KEY,
    maxAttempts = 3,
    delayMillis = 3000L,
    exhaustedState = PaymentState.DEBIT_AUTHORIZATION_FAILED
)
public class DebitAuthorizationConsumer implements Consumer<PayId> {

  private final LedgerRepository ledger;
  private final DebitGateway debitGateway;
  private final PayProducer producer;

  @Override
  @Transactional
  @RabbitListener(queues = PayTopology.DEBIT_AUTHORIZATION_QUEUE)
  public void consume(PayId payId) {
    Ledger entry = ledger.findById(payId.id())
        .orElseThrow(() -> new IllegalStateException("Ledger entry not found: " + payId.id()));

    if (!entry.getState().awaitingDebitAuthorization()) {
      log.info("Skipping debit authorization for id={} state={}", payId.id(), entry.getState());
      return;
    }

    entry.markDebitAuthorizationPending();

    switch (debitGateway.debit(entry)) {
      case DebitResult.Approved() -> {
        entry.markDebitAuthorized();
        producer.publishCreditAuthorization(payId);
        log.info("Debit authorized for id={} — queued credit", payId.id());
      }
      case DebitResult.Declined(String reasonCode) -> {
        entry.markDebitDeclined();
        log.info("Debit declined for id={} reason={}", payId.id(), reasonCode);
      }
    }
  }
}

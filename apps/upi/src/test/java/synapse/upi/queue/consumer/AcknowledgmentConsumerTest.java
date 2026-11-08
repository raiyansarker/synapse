package synapse.upi.queue.consumer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.ack.interfaces.AckGateway;
import synapse.upi.pay.ack.interfaces.AckResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;

@ExtendWith(MockitoExtension.class)
class AcknowledgmentConsumerTest {

  @Mock
  private LedgerRepository ledgerRepository;

  @Mock
  private AckGateway ackGateway;

  @Mock
  private PayProducer producer;

  private AcknowledgmentConsumer consumer;

  @BeforeEach
  void setUp() {
    consumer = new AcknowledgmentConsumer(ledgerRepository, ackGateway, producer);
  }

  @Test
  void completesWhenAckSucceeds() {
    Ledger entry = creditAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(ackGateway.acknowledge(entry)).thenReturn(new AckResult.Succeeded());

    consumer.consume(payId);

    assertEquals(PaymentState.COMPLETED, entry.getState());
    verify(producer, never()).publishReversal(payId);
  }

  @Test
  void queuesReversalWhenAckFails() {
    Ledger entry = creditAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(ackGateway.acknowledge(entry)).thenReturn(new AckResult.Failed("NOTIFY_REJECTED"));

    consumer.consume(payId);

    assertEquals(PaymentState.REVERSAL_PENDING, entry.getState());
    verify(producer).publishReversal(payId);
  }

  @Test
  void skipsWhenNotAwaitingAcknowledgment() {
    Ledger entry = creditAuthorized();
    entry.markCompleted();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));

    consumer.consume(payId);

    verify(ackGateway, never()).acknowledge(entry);
  }

  private static Ledger creditAuthorized() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));
    entry.markDebitAuthorized();
    entry.markCreditAuthorized();
    return entry;
  }
}

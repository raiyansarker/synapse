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
import synapse.upi.pay.reversal.interfaces.ReversalGateway;
import synapse.upi.pay.reversal.interfaces.ReversalResult;
import synapse.upi.queue.message.PayId;

@ExtendWith(MockitoExtension.class)
class ReversalConsumerTest {

  @Mock
  private LedgerRepository ledgerRepository;

  @Mock
  private ReversalGateway reversalGateway;

  private ReversalConsumer consumer;

  @BeforeEach
  void setUp() {
    consumer = new ReversalConsumer(ledgerRepository, reversalGateway);
  }

  @Test
  void marksReversedWhenBankSucceeds() {
    Ledger entry = reversalPending();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(reversalGateway.reverse(entry)).thenReturn(new ReversalResult.Reversed());

    consumer.consume(payId);

    assertEquals(PaymentState.REVERSED, entry.getState());
  }

  @Test
  void marksReversalFailedWhenBankRefuses() {
    Ledger entry = reversalPending();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(reversalGateway.reverse(entry)).thenReturn(new ReversalResult.Failed("REVERSE_REJECTED"));

    consumer.consume(payId);

    assertEquals(PaymentState.REVERSAL_FAILED, entry.getState());
  }

  @Test
  void skipsWhenNotAwaitingReversal() {
    Ledger entry = reversalPending();
    entry.markReversed();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));

    consumer.consume(payId);

    verify(reversalGateway, never()).reverse(entry);
  }

  private static Ledger reversalPending() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));
    entry.markDebitAuthorized();
    entry.markReversalPending();
    return entry;
  }
}

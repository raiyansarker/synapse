package synapse.upi.queue.consumer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
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
import synapse.upi.pay.debit.interfaces.DebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;

@ExtendWith(MockitoExtension.class)
class DebitAuthorizationConsumerTest {

  @Mock
  private LedgerRepository ledgerRepository;

  @Mock
  private DebitGateway debitGateway;

  @Mock
  private PayProducer producer;

  private DebitAuthorizationConsumer consumer;

  @BeforeEach
  void setUp() {
    consumer = new DebitAuthorizationConsumer(ledgerRepository, debitGateway, producer);
  }

  @Test
  void authorizesAndQueuesCreditWhenBankApproves() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(debitGateway.debit(entry)).thenReturn(new DebitResult.Approved());

    consumer.consume(payId);

    assertEquals(PaymentState.DEBIT_AUTHORIZED, entry.getState());
    verify(producer).publishCreditAuthorization(payId);
  }

  @Test
  void declinesWhenBankRefuses() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(debitGateway.debit(entry)).thenReturn(new DebitResult.Declined("INSUFFICIENT_FUNDS"));

    consumer.consume(payId);

    assertEquals(PaymentState.DEBIT_DECLINED, entry.getState());
    verify(producer, never()).publishCreditAuthorization(payId);
  }

  @Test
  void skipsWhenNotAwaitingDebitAuthorization() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));
    entry.markDebitAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));

    consumer.consume(payId);

    verify(debitGateway, never()).debit(entry);
    assertEquals(PaymentState.DEBIT_AUTHORIZED, entry.getState());
  }

  @Test
  void reprocessesWhenAlreadyPending() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));
    entry.markDebitAuthorizationPending();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(debitGateway.debit(entry)).thenReturn(new DebitResult.Approved());

    consumer.consume(payId);

    assertEquals(PaymentState.DEBIT_AUTHORIZED, entry.getState());
    verify(producer).publishCreditAuthorization(payId);
  }

  @Test
  void propagatesTransientGatewayFailures() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(debitGateway.debit(entry)).thenThrow(new RuntimeException("bank timeout"));

    assertThrows(RuntimeException.class, () -> consumer.consume(payId));
    assertEquals(PaymentState.DEBIT_AUTHORIZATION_PENDING, entry.getState());
  }

  @Test
  void failsWhenLedgerRowIsMissing() {
    PayId payId = new PayId("missing");
    when(ledgerRepository.findById("missing")).thenReturn(Optional.empty());

    assertThrows(IllegalStateException.class, () -> consumer.consume(payId));
    verify(debitGateway, never()).debit(org.mockito.ArgumentMatchers.any());
  }
}

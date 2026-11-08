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
import synapse.upi.pay.credit.interfaces.CreditGateway;
import synapse.upi.pay.credit.interfaces.CreditResult;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;

@ExtendWith(MockitoExtension.class)
class CreditAuthorizationConsumerTest {

  @Mock
  private LedgerRepository ledgerRepository;

  @Mock
  private CreditGateway creditGateway;

  @Mock
  private PayProducer producer;

  private CreditAuthorizationConsumer consumer;

  @BeforeEach
  void setUp() {
    consumer = new CreditAuthorizationConsumer(ledgerRepository, creditGateway, producer);
  }

  @Test
  void authorizesAndQueuesAckWhenBankApproves() {
    Ledger entry = debitAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(creditGateway.credit(entry)).thenReturn(new CreditResult.Approved());

    consumer.consume(payId);

    assertEquals(PaymentState.CREDIT_AUTHORIZED, entry.getState());
    verify(producer).publishAcknowledgment(payId);
  }

  @Test
  void queuesReversalWhenBankDeclines() {
    Ledger entry = debitAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));
    when(creditGateway.credit(entry)).thenReturn(new CreditResult.Declined("ACCOUNT_CLOSED"));

    consumer.consume(payId);

    assertEquals(PaymentState.REVERSAL_PENDING, entry.getState());
    verify(producer).publishReversal(payId);
    verify(producer, never()).publishAcknowledgment(payId);
  }

  @Test
  void skipsWhenNotAwaitingCreditAuthorization() {
    Ledger entry = debitAuthorized();
    entry.markCreditAuthorized();
    PayId payId = new PayId(entry.getId());
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));

    consumer.consume(payId);

    verify(creditGateway, never()).credit(entry);
  }

  private static Ledger debitAuthorized() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));
    entry.markDebitAuthorized();
    return entry;
  }
}

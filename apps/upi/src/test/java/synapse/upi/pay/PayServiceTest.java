package synapse.upi.pay;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.ledger.PaymentState;
import synapse.upi.pay.dto.AcceptPayRequest;
import synapse.upi.queue.message.PayId;
import synapse.upi.queue.producer.PayProducer;

@ExtendWith(MockitoExtension.class)
class PayServiceTest {

  @Mock
  private LedgerRepository ledgerRepository;

  @Mock
  private PayProducer producer;

  private PayService payService;

  @BeforeEach
  void setUp() {
    payService = new PayService(ledgerRepository, producer);
  }

  @Test
  void acceptPersistsAndPublishesPayId() {
    AcceptPayRequest request =
        new AcceptPayRequest("wow@brac", new BigDecimal("99.99"), "bruh@city");
    when(ledgerRepository.save(any(Ledger.class))).thenAnswer(invocation -> invocation.getArgument(0));

    String id = payService.accept(request);

    ArgumentCaptor<PayId> published = ArgumentCaptor.forClass(PayId.class);
    verify(producer).publishDebitAuthorization(published.capture());

    assertEquals(id, published.getValue().id());
  }

  @Test
  void getPayStateReturnsLedgerState() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("5.00"));
    entry.markDebitAuthorized();
    when(ledgerRepository.findById(entry.getId())).thenReturn(Optional.of(entry));

    Optional<PaymentState> state = payService.getPayState(entry.getId());

    assertTrue(state.isPresent());
    assertEquals(PaymentState.DEBIT_AUTHORIZED, state.get());
  }

  @Test
  void getPayStateIsEmptyWhenMissing() {
    when(ledgerRepository.findById("missing")).thenReturn(Optional.empty());

    assertTrue(payService.getPayState("missing").isEmpty());
  }
}

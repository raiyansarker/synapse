package synapse.upi.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class LedgerTest {

  @Test
  void acceptedStartsInAccepted() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("99.99"));

    assertEquals(PaymentState.ACCEPTED, entry.getState());
    assertEquals("wow@brac", entry.getSva());
    assertEquals("bruh@city", entry.getRva());
    assertEquals(new BigDecimal("99.99"), entry.getAmount());
  }

  @Test
  void debitAuthorizationPath() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));

    entry.markDebitAuthorizationPending();
    assertEquals(PaymentState.DEBIT_AUTHORIZATION_PENDING, entry.getState());

    entry.markDebitAuthorized();
    assertEquals(PaymentState.DEBIT_AUTHORIZED, entry.getState());
  }

  @Test
  void debitDeclineIsTerminal() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));

    entry.markDebitAuthorizationPending();
    entry.markDebitDeclined();

    assertEquals(PaymentState.DEBIT_DECLINED, entry.getState());
  }

  @Test
  void debitAuthorizationFailureIsTerminal() {
    Ledger entry = Ledger.accepted("wow@brac", "bruh@city", new BigDecimal("10.00"));

    entry.markDebitAuthorizationFailed();

    assertEquals(PaymentState.DEBIT_AUTHORIZATION_FAILED, entry.getState());
  }
}

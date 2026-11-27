package synapse.bank.ledger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import synapse.bank.account.Account;
import synapse.bank.account.InsufficientFundsException;

class LedgerTest {

  @Test
  void creditMutatesAccountAndRecordsEntry() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    Ledger entry = Ledger.credit(account, new BigDecimal("5.50"), "pay-1");

    assertNotNull(entry.getId());
    assertEquals(account, entry.getAccount());
    assertEquals(EntryType.CREDIT, entry.getType());
    assertMoney("5.50", entry.getAmount());
    assertMoney("15.50", entry.getBalanceAfter());
    assertEquals("pay-1", entry.getReference());
    assertMoney("15.50", account.getBalance());
  }

  @Test
  void debitMutatesAccountAndRecordsEntry() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    Ledger entry = Ledger.debit(account, new BigDecimal("4.00"), null);

    assertEquals(EntryType.DEBIT, entry.getType());
    assertMoney("4.00", entry.getAmount());
    assertMoney("6.00", entry.getBalanceAfter());
    assertNull(entry.getReference());
    assertMoney("6.00", account.getBalance());
  }

  @Test
  void debitRejectsInsufficientFundsWithoutRecording() {
    Account account = Account.open("raiyan", new BigDecimal("1.00"));

    assertThrows(
        InsufficientFundsException.class,
        () -> Ledger.debit(account, new BigDecimal("2.00"), "x"));
    assertMoney("1.00", account.getBalance());
  }

  @Test
  void rejectsBadAmountsAndMissingAccount() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    assertThrows(IllegalArgumentException.class, () -> Ledger.credit(account, BigDecimal.ZERO, null));
    assertThrows(IllegalArgumentException.class, () -> Ledger.debit(account, new BigDecimal("-1"), null));
    assertThrows(IllegalArgumentException.class, () -> Ledger.credit(account, new BigDecimal("0.001"), null));
    assertThrows(IllegalArgumentException.class, () -> Ledger.credit(null, new BigDecimal("1"), null));
    assertMoney("10.00", account.getBalance());
  }

  private static void assertMoney(String expected, BigDecimal actual) {
    assertEquals(0, new BigDecimal(expected).compareTo(actual), "expected " + expected + " but was " + actual);
  }
}

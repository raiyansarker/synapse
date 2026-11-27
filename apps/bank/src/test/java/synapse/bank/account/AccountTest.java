package synapse.bank.account;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class AccountTest {

  @Test
  void openStartsActiveWithZeroBalance() {
    Account account = Account.open("raiyan");

    assertNotNull(account.getId());
    assertEquals("raiyan", account.getVirtualAddress());
    assertEquals(AccountStatus.ACTIVE, account.getStatus());
    assertMoney("0", account.getBalance());
  }

  @Test
  void openWithInitialBalance() {
    Account account = Account.open("raiyan", new BigDecimal("100.50"));

    assertEquals(AccountStatus.ACTIVE, account.getStatus());
    assertMoney("100.50", account.getBalance());
  }

  @Test
  void openRejectsMalformedVirtualAddress() {
    assertThrows(IllegalArgumentException.class, () -> Account.open("raiyan@city"));
    assertThrows(IllegalArgumentException.class, () -> Account.open("Raiyan"));
    assertThrows(IllegalArgumentException.class, () -> Account.open("raiyan city"));
    assertThrows(IllegalArgumentException.class, () -> Account.open(""));
    assertThrows(IllegalArgumentException.class, () -> Account.open(null));
  }

  @Test
  void openRejectsNegativeInitialBalance() {
    assertThrows(
        IllegalArgumentException.class, () -> Account.open("raiyan", new BigDecimal("-1")));
  }

  @Test
  void creditIncreasesBalance() {
    Account account = Account.open("raiyan");

    account.credit(new BigDecimal("25.00"));
    account.credit(new BigDecimal("0.99"));

    assertMoney("25.99", account.getBalance());
  }

  @Test
  void creditRejectsNonPositiveAmount() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    assertThrows(IllegalArgumentException.class, () -> account.credit(BigDecimal.ZERO));
    assertThrows(IllegalArgumentException.class, () -> account.credit(new BigDecimal("-5")));
    assertMoney("10.00", account.getBalance());
  }

  @Test
  void creditRejectsSubCentAmount() {
    Account account = Account.open("raiyan");

    assertThrows(IllegalArgumentException.class, () -> account.credit(new BigDecimal("0.001")));
  }

  @Test
  void debitDecreasesBalance() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    account.debit(new BigDecimal("4.50"));

    assertMoney("5.50", account.getBalance());
  }

  @Test
  void debitRejectsInsufficientFunds() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    InsufficientFundsException error =
        assertThrows(
            InsufficientFundsException.class, () -> account.debit(new BigDecimal("10.01")));

    assertEquals("raiyan", error.getVirtualAddress());
    assertMoney("10.00", error.getBalance());
    assertMoney("10.01", error.getRequested());
    assertMoney("10.00", account.getBalance());
  }

  @Test
  void debitRejectsNonPositiveAmount() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    assertThrows(IllegalArgumentException.class, () -> account.debit(BigDecimal.ZERO));
    assertThrows(IllegalArgumentException.class, () -> account.debit(new BigDecimal("-1")));
  }

  @Test
  void frozenAccountRejectsMoneyMovementUntilUnfrozen() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    account.freeze();
    assertEquals(AccountStatus.FROZEN, account.getStatus());
    assertThrows(IllegalStateException.class, () -> account.credit(new BigDecimal("1")));
    assertThrows(IllegalStateException.class, () -> account.debit(new BigDecimal("1")));

    account.unfreeze();
    assertEquals(AccountStatus.ACTIVE, account.getStatus());
    account.credit(new BigDecimal("1"));
    assertMoney("11.00", account.getBalance());
  }

  @Test
  void closeRequiresZeroBalanceAndIsTerminal() {
    Account account = Account.open("raiyan", new BigDecimal("10.00"));

    assertThrows(IllegalStateException.class, account::close);
    assertEquals(AccountStatus.ACTIVE, account.getStatus());

    account.debit(new BigDecimal("10.00"));
    account.close();

    assertEquals(AccountStatus.CLOSED, account.getStatus());
    assertTrue(account.getStatus().terminal());
    assertThrows(IllegalStateException.class, () -> account.credit(new BigDecimal("1")));
    assertThrows(IllegalStateException.class, () -> account.debit(new BigDecimal("1")));
    assertThrows(IllegalStateException.class, account::freeze);
    assertThrows(IllegalStateException.class, account::unfreeze);
    assertThrows(IllegalStateException.class, account::close);
  }

  private static void assertMoney(String expected, BigDecimal actual) {
    assertEquals(0, new BigDecimal(expected).compareTo(actual), "expected " + expected + " but was " + actual);
  }
}

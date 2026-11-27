package synapse.bank.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import synapse.bank.account.Account;

class UserTest {

  @Test
  void registerCreatesCustomerWithId() {
    User user = User.register("raiyan", "$2a$10$encodedhash", "$2a$10$encodedpin");

    assertNotNull(user.getId());
    assertEquals("raiyan", user.getUsername());
    assertEquals("$2a$10$encodedhash", user.getPassword());
    assertEquals("$2a$10$encodedpin", user.getPin());
    assertEquals(Role.CUSTOMER, user.getRole());
  }

  @Test
  void registerWithExplicitRole() {
    User staff = User.register("boss", "hash", "pinhash", Role.STAFF);

    assertEquals(Role.STAFF, staff.getRole());
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "hash", "pinhash", null));
  }

  @Test
  void registerRejectsMalformedUsername() {
    assertThrows(IllegalArgumentException.class, () -> User.register("Raiyan", "hash", "pinhash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan@city", "hash", "pinhash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("", "hash", "pinhash"));
    assertThrows(IllegalArgumentException.class, () -> User.register(null, "hash", "pinhash"));
  }

  @Test
  void registerRejectsBlankPasswordOrPin() {
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", null, "pinhash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "  ", "pinhash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "hash", null));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "hash", " "));
  }

  @Test
  void assignAccountLinksAccountWithSameUsername() {
    User user = User.register("raiyan", "hash", "pinhash");
    Account account = Account.open("raiyan");

    user.assignAccount(account);

    assertEquals(account, user.getAccount());
  }

  @Test
  void assignAccountRejectsMismatchedOrNullAccount() {
    User user = User.register("raiyan", "hash", "pinhash");

    assertThrows(IllegalArgumentException.class, () -> user.assignAccount(Account.open("other")));
    assertThrows(IllegalArgumentException.class, () -> user.assignAccount(null));
  }
}

package synapse.bank.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import synapse.bank.account.Account;

class UserTest {

  @Test
  void registerCreatesCustomerWithId() {
    User user = User.register("raiyan", "$2a$10$encodedhash");

    assertNotNull(user.getId());
    assertEquals("raiyan", user.getUsername());
    assertEquals("$2a$10$encodedhash", user.getPassword());
    assertEquals(Role.CUSTOMER, user.getRole());
  }

  @Test
  void registerWithExplicitRole() {
    User staff = User.register("boss", "hash", Role.STAFF);

    assertEquals(Role.STAFF, staff.getRole());
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "hash", null));
  }

  @Test
  void registerRejectsMalformedUsername() {
    assertThrows(IllegalArgumentException.class, () -> User.register("Raiyan", "hash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan@city", "hash"));
    assertThrows(IllegalArgumentException.class, () -> User.register("", "hash"));
    assertThrows(IllegalArgumentException.class, () -> User.register(null, "hash"));
  }

  @Test
  void registerRejectsBlankPassword() {
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", null));
    assertThrows(IllegalArgumentException.class, () -> User.register("raiyan", "  "));
  }

  @Test
  void assignAccountLinksAccountWithSameUsername() {
    User user = User.register("raiyan", "hash");
    Account account = Account.open("raiyan");

    user.assignAccount(account);

    assertEquals(account, user.getAccount());
  }

  @Test
  void assignAccountRejectsMismatchedOrNullAccount() {
    User user = User.register("raiyan", "hash");

    assertThrows(IllegalArgumentException.class, () -> user.assignAccount(Account.open("other")));
    assertThrows(IllegalArgumentException.class, () -> user.assignAccount(null));
  }
}

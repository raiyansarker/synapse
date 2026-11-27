package synapse.bank.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class UserTest {

  @Test
  void registerStartsEnabledWithId() {
    User user = User.register("raiyan", "$2a$10$encodedhash");

    assertNotNull(user.getId());
    assertEquals("raiyan", user.getUsername());
    assertEquals("$2a$10$encodedhash", user.getPassword());
    assertTrue(user.isEnabled());
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
  void changePasswordReplacesHashAndRejectsBlank() {
    User user = User.register("raiyan", "oldhash");

    user.changePassword("newhash");
    assertEquals("newhash", user.getPassword());

    assertThrows(IllegalArgumentException.class, () -> user.changePassword(""));
    assertEquals("newhash", user.getPassword());
  }

  @Test
  void disableAndEnableToggle() {
    User user = User.register("raiyan", "hash");

    user.disable();
    assertFalse(user.isEnabled());

    user.enable();
    assertTrue(user.isEnabled());
  }
}

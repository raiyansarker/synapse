package synapse.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class VirtualAddressTest {

  @Test
  void splitsTheUsernameAndTheBank() {
    VirtualAddress address = VirtualAddress.parse("mina@city");

    assertEquals("mina", address.username());
    assertEquals("city", address.bankIdentifier());
    assertEquals("mina@city", address.toString());
  }

  @Test
  void acceptsDigitsInTheUsername() {
    VirtualAddress address = VirtualAddress.parse("user1@brac");

    assertEquals("user1", address.username());
    assertEquals("brac", address.bankIdentifier());
  }

  @Test
  void rejectsAPaddedOrBlankSide() {
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse("a@ "));
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse(" mina@city"));
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse("mina@city "));
  }

  @ParameterizedTest
  @ValueSource(
      strings = {
        "Mina@city",
        "mina@City",
        "mina.user@city",
        "mina@city.bank",
        "mina@ucb1",
        "mina-user@city",
        "mina@city-bank"
      })
  void rejectsIllegalCharacters(String value) {
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse(value));
  }
}

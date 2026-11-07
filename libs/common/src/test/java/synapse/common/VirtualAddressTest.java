package synapse.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class VirtualAddressTest {

  @Test
  void splitsTheUsernameAndTheBank() {
    VirtualAddress address = VirtualAddress.parse("mina@city");

    assertEquals("mina", address.getUsername());
    assertEquals("city", address.getBankIdentifier());
    assertEquals("mina@city", address.toString());
  }

  @Test
  void rejectsAPaddedOrBlankSide() {
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse("a@ "));
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse(" mina@city"));
    assertThrows(IllegalArgumentException.class, () -> VirtualAddress.parse("mina@city "));
  }
}

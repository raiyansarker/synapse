package synapse.common.validation;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class VirtualAddressValidatorTest {

  @Test
  void acceptsANameAndABank() {
    assertTrue(VirtualAddressValidator.matches("mina@city"));
  }

  @Test
  void rejectsAValueWithoutOneAt() {
    assertFalse(VirtualAddressValidator.matches(null));
    assertFalse(VirtualAddressValidator.matches("mina"));
    assertFalse(VirtualAddressValidator.matches("@city"));
    assertFalse(VirtualAddressValidator.matches("mina@"));
    assertFalse(VirtualAddressValidator.matches("a@ "));
    assertFalse(VirtualAddressValidator.matches(" mina@city"));
    assertFalse(VirtualAddressValidator.matches("mina@city "));
    assertFalse(VirtualAddressValidator.matches("mina@city@extra"));
    assertFalse(VirtualAddressValidator.matches("Mina@city"));
  }
}

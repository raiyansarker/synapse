package synapse.common.validation;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class VaValidatorTest {

  @Test
  void acceptsANameAndABank() {
    assertTrue(VaValidator.matches("mina@city"));
  }

  @Test
  void rejectsAValueWithoutOneAt() {
    assertFalse(VaValidator.matches(null));
    assertFalse(VaValidator.matches("mina"));
    assertFalse(VaValidator.matches("@city"));
    assertFalse(VaValidator.matches("mina@"));
    assertFalse(VaValidator.matches("mina@city@extra"));
  }
}

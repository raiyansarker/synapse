package synapse.common.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/**
 * Bean Validation check for {@link VirtualAddress}. Null is left to {@code @NotBlank}. The rule is
 * {@link synapse.common.VirtualAddress#matches(String)}.
 */
public class VirtualAddressValidator implements ConstraintValidator<VirtualAddress, String> {

  public static boolean matches(String value) {
    return synapse.common.VirtualAddress.matches(value);
  }

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    return value == null || matches(value);
  }
}

package synapse.common.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/** Bean Validation check for {@link VirtualAddress}. Null is left to {@code @NotBlank}. */
public class VirtualAddressValidator implements ConstraintValidator<VirtualAddress, String> {

  public static boolean matches(String value) {
    int at = value == null ? -1 : value.indexOf('@');
    return at > 0 && at == value.lastIndexOf('@') && at < value.length() - 1;
  }

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    return value == null || matches(value);
  }
}

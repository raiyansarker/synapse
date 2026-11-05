package synapse.upi.payment;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/** Bean Validation check for {@link Va}. Null is left to {@code @NotBlank}. */
public class VaValidator implements ConstraintValidator<Va, String> {

  static boolean matches(String value) {
    int at = value == null ? -1 : value.indexOf('@');
    return at > 0 && at == value.lastIndexOf('@') && at < value.length() - 1;
  }

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    return value == null || matches(value);
  }
}

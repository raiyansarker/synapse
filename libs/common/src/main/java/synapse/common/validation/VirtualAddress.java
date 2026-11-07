package synapse.common.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * A virtual address, {@code name@bank}. Both sides are trimmed and must be non-blank, the text must
 * already be that trimmed form, and the username must be lowercase.
 */
@Documented
@Constraint(validatedBy = VirtualAddressValidator.class)
@Target({
  ElementType.FIELD,
  ElementType.METHOD,
  ElementType.PARAMETER,
  ElementType.RECORD_COMPONENT
})
@Retention(RetentionPolicy.RUNTIME)
public @interface VirtualAddress {

  String message() default "must look like name@bank";

  Class<?>[] groups() default {};

  Class<? extends Payload>[] payload() default {};
}

package synapse.upi.payment;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

/**
 * One payment tracked by the switch. {@code atomicId} is the id returned to the bank that published it.
 */
public record Payment(
    String atomicId,
    PaymentState state,
    String payerVa,
    String payeeVa,
    BigDecimal amount) implements Serializable {

  private static final long serialVersionUID = 3L;

  public Payment {
    Objects.requireNonNull(atomicId, "atomicId");
    Objects.requireNonNull(state, "state");
    requireVa(payerVa, "payerVa");
    requireVa(payeeVa, "payeeVa");
    Objects.requireNonNull(amount, "amount");
    if (amount.signum() <= 0) {
      throw new IllegalArgumentException("amount must be positive");
    }
  }

  public static Payment accept(String payerVa, String payeeVa, BigDecimal amount) {
    return new Payment(UUID.randomUUID().toString(), PaymentState.ACCEPTED, payerVa, payeeVa, amount);
  }

  public Payment withState(PaymentState next) {
    return new Payment(atomicId, next, payerVa, payeeVa, amount);
  }

  private static void requireVa(String value, String label) {
    int at = value == null ? -1 : value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
      throw new IllegalArgumentException(label + " must look like name@bank");
    }
  }
}

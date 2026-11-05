package synapse.upi.payment;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * One payment tracked by the switch. {@code atomicId} is the id returned to the bank that published it.
 */
public record Payment(
    String atomicId,
    PaymentState state,
    String payerVirtualAddress,
    String payeeVirtualAddress,
    BigDecimal amount,
    Map<String, String> metadata) implements Serializable {

  private static final long serialVersionUID = 2L;

  public Payment {
    Objects.requireNonNull(atomicId, "atomicId");
    Objects.requireNonNull(state, "state");
    requireVirtualAddress(payerVirtualAddress, "payerVirtualAddress");
    requireVirtualAddress(payeeVirtualAddress, "payeeVirtualAddress");
    Objects.requireNonNull(amount, "amount");
    if (amount.signum() <= 0) {
      throw new IllegalArgumentException("amount must be positive");
    }
    metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
  }

  public static Payment accept(
      String payerVirtualAddress,
      String payeeVirtualAddress,
      BigDecimal amount,
      Map<String, String> metadata) {
    return new Payment(
        UUID.randomUUID().toString(),
        PaymentState.ACCEPTED,
        payerVirtualAddress,
        payeeVirtualAddress,
        amount,
        metadata);
  }

  public Payment withState(PaymentState next) {
    return new Payment(atomicId, next, payerVirtualAddress, payeeVirtualAddress, amount, metadata);
  }

  private static void requireVirtualAddress(String value, String label) {
    int at = value == null ? -1 : value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
      throw new IllegalArgumentException(label + " must look like name@bank");
    }
  }
}

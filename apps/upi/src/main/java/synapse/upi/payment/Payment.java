package synapse.upi.payment;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

/**
 * One payment tracked by the switch. {@code atomicId} is the id returned to the bank that published it.
 *
 * @param sva sender virtual address, {@code name@bank}. The address the money leaves.
 * @param rva receiver virtual address, {@code name@bank}. Used to find the receiver's bank.
 */
public record Payment(
    String atomicId,
    PaymentState state,
    String sva,
    String rva,
    BigDecimal amount) implements Serializable {

  private static final long serialVersionUID = 4L;

  public Payment {
    Objects.requireNonNull(atomicId, "atomicId");
    Objects.requireNonNull(state, "state");
    requireVa(sva, "sva");
    requireVa(rva, "rva");
    Objects.requireNonNull(amount, "amount");
    if (amount.signum() <= 0) {
      throw new IllegalArgumentException("amount must be positive");
    }
  }

  public static Payment accept(String sva, String rva, BigDecimal amount) {
    return new Payment(UUID.randomUUID().toString(), PaymentState.ACCEPTED, sva, rva, amount);
  }

  public Payment withState(PaymentState next) {
    return new Payment(atomicId, next, sva, rva, amount);
  }

  private static void requireVa(String value, String label) {
    if (!VaValidator.matches(value)) {
      throw new IllegalArgumentException(label + " must look like name@bank");
    }
  }
}

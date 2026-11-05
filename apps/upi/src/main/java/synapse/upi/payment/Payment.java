package synapse.upi.payment;

import java.util.Objects;
import java.util.UUID;

/**
 * One payment tracked by the switch. {@code atomicId} is the id returned to the bank that published it.
 */
public record Payment(
    String atomicId,
    PaymentState state,
    String payerVirtualAddress,
    String payeeVirtualAddress) {

  public Payment {
    Objects.requireNonNull(atomicId, "atomicId");
    Objects.requireNonNull(state, "state");
    requireVirtualAddress(payerVirtualAddress, "payerVirtualAddress");
    requireVirtualAddress(payeeVirtualAddress, "payeeVirtualAddress");
  }

  public static Payment accept(String payerVirtualAddress, String payeeVirtualAddress) {
    return new Payment(
        UUID.randomUUID().toString(),
        PaymentState.ACCEPTED,
        payerVirtualAddress,
        payeeVirtualAddress);
  }

  public Payment withState(PaymentState next) {
    return new Payment(atomicId, next, payerVirtualAddress, payeeVirtualAddress);
  }

  private static void requireVirtualAddress(String value, String label) {
    int at = value == null ? -1 : value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
      throw new IllegalArgumentException(label + " must look like name@bank");
    }
  }
}

package synapse.upi.payment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;
import synapse.upi.payment.statemachine.PaymentState;

class PaymentTest {

  @Test
  void acceptMintsAnIdAndStartsAccepted() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("10.00"));

    UUID.fromString(payment.atomicId());
    assertEquals(PaymentState.ACCEPTED, payment.state());
    assertEquals("mina@city", payment.sva());
    assertEquals("raiyan@city", payment.rva());
    assertEquals(0, payment.amount().compareTo(new BigDecimal("10.00")));
    assertNotEquals(
        payment.atomicId(), Payment.accept("mina@city", "raiyan@city", BigDecimal.ONE).atomicId());
  }

  @Test
  void withStateKeepsTheIdentityAndTheMoney() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("10.00"));

    Payment next = payment.withState(PaymentState.AUTHORIZED);

    assertEquals(PaymentState.AUTHORIZED, next.state());
    assertEquals(payment.atomicId(), next.atomicId());
    assertEquals(payment.sva(), next.sva());
    assertEquals(payment.rva(), next.rva());
    assertEquals(payment.amount(), next.amount());
  }

  @ParameterizedTest
  @NullAndEmptySource
  @ValueSource(strings = {"mina", "@city", "mina@", "mina@city@extra"})
  void rejectsABadSenderAddress(String sva) {
    assertThrows(
        IllegalArgumentException.class, () -> Payment.accept(sva, "raiyan@city", BigDecimal.ONE));
  }

  @ParameterizedTest
  @NullAndEmptySource
  @ValueSource(strings = {"raiyan", "@city", "raiyan@", "raiyan@city@extra"})
  void rejectsABadReceiverAddress(String rva) {
    assertThrows(
        IllegalArgumentException.class, () -> Payment.accept("mina@city", rva, BigDecimal.ONE));
  }

  @ParameterizedTest
  @ValueSource(strings = {"0", "-1", "-0.01"})
  void rejectsANonPositiveAmount(String amount) {
    assertThrows(
        IllegalArgumentException.class,
        () -> Payment.accept("mina@city", "raiyan@city", new BigDecimal(amount)));
  }
}

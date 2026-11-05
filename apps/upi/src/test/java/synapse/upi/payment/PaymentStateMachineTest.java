package synapse.upi.payment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

@SpringJUnitConfig(classes = {PaymentStateMachineConfig.class, PaymentStateMachine.class})
class PaymentStateMachineTest {

  @Autowired
  private PaymentStateMachine machine;

  @Test
  void happyPathKeepsTheAtomicId() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("1.00"));
    String atomicId = payment.atomicId();

    payment = machine.apply(payment, PaymentEvent.VPA_RESOLVED);
    assertEquals(PaymentState.AUTHORIZATION_PENDING, payment.state());

    payment = machine.apply(payment, PaymentEvent.DEBIT_APPROVED);
    assertEquals(PaymentState.AUTHORIZED, payment.state());

    payment = machine.apply(payment, PaymentEvent.CREDIT_REQUESTED);
    assertEquals(PaymentState.CREDIT_PENDING, payment.state());

    payment = machine.apply(payment, PaymentEvent.CREDIT_APPROVED);
    assertEquals(PaymentState.ACKNOWLEDGING, payment.state());

    payment = machine.apply(payment, PaymentEvent.PAYER_ACKNOWLEDGED);
    assertEquals(PaymentState.COMPLETED, payment.state());
    assertEquals(atomicId, payment.atomicId());
    assertTrue(payment.state().terminal());
  }

  @Test
  void unresolvedVirtualAddressEndsThePayment() {
    Payment payment = machine.apply(
        Payment.accept("mina@city", "raiyan@city", new BigDecimal("1.00")), PaymentEvent.VPA_UNRESOLVED);

    assertEquals(PaymentState.RESOLUTION_FAILED, payment.state());
  }

  @Test
  void declinedDebitEndsThePayment() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("1.00"));
    payment = machine.apply(payment, PaymentEvent.VPA_RESOLVED);
    payment = machine.apply(payment, PaymentEvent.DEBIT_DECLINED);

    assertEquals(PaymentState.DECLINED, payment.state());
  }

  @Test
  void rejectedCreditReversesTheDebit() {
    Payment payment = credited();
    payment = machine.apply(payment, PaymentEvent.CREDIT_REJECTED);
    assertEquals(PaymentState.REVERSAL_PENDING, payment.state());

    payment = machine.apply(payment, PaymentEvent.REVERSAL_APPROVED);
    assertEquals(PaymentState.REVERSED, payment.state());
  }

  @Test
  void failedPayerAcknowledgementReversesTheCredit() {
    Payment payment = credited();
    payment = machine.apply(payment, PaymentEvent.CREDIT_APPROVED);
    assertEquals(PaymentState.ACKNOWLEDGING, payment.state());

    payment = machine.apply(payment, PaymentEvent.PAYER_ACK_FAILED);
    assertEquals(PaymentState.REVERSAL_PENDING, payment.state());

    payment = machine.apply(payment, PaymentEvent.REVERSAL_APPROVED);
    assertEquals(PaymentState.REVERSED, payment.state());
  }

  @Test
  void failedReversalStaysUnsettled() {
    Payment payment = credited();
    payment = machine.apply(payment, PaymentEvent.CREDIT_REJECTED);
    payment = machine.apply(payment, PaymentEvent.REVERSAL_REJECTED);

    assertEquals(PaymentState.REVERSAL_FAILED, payment.state());
  }

  @Test
  void rejectsAnEventTheCurrentStateDoesNotAllow() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("1.00"));

    IllegalPaymentTransitionException error = assertThrows(
        IllegalPaymentTransitionException.class,
        () -> machine.apply(payment, PaymentEvent.CREDIT_APPROVED));

    assertEquals(PaymentState.ACCEPTED, error.state());
    assertEquals(PaymentEvent.CREDIT_APPROVED, error.event());
  }

  @Test
  void terminalStatesAcceptNoEvents() {
    for (PaymentState state : PaymentState.values()) {
      if (!state.terminal()) {
        continue;
      }
      for (PaymentEvent event : PaymentEvent.values()) {
        assertThrows(
            IllegalPaymentTransitionException.class,
            () -> machine.transit(state, event),
            state + " accepted " + event);
      }
    }
  }

  @Test
  void exposesElevenStatesAndTenTransitions() {
    assertEquals(11, PaymentState.values().length);

    int transitions = 0;
    for (PaymentState state : PaymentState.values()) {
      transitions += machine.eventsFrom(state).size();
    }
    assertEquals(11, transitions);
  }

  private Payment credited() {
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("1.00"));
    payment = machine.apply(payment, PaymentEvent.VPA_RESOLVED);
    payment = machine.apply(payment, PaymentEvent.DEBIT_APPROVED);
    return machine.apply(payment, PaymentEvent.CREDIT_REQUESTED);
  }
}

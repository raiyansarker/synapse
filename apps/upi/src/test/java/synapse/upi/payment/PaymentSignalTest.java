package synapse.upi.payment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

class PaymentSignalTest {

  @Test
  void routesBankRepliesToTheirTopics() {
    assertEquals(PaymentSignal.DEBIT, PaymentSignal.topic(PaymentEvent.DEBIT_APPROVED));
    assertEquals(PaymentSignal.DEBIT, PaymentSignal.topic(PaymentEvent.DEBIT_DECLINED));
    assertEquals(PaymentSignal.CREDIT, PaymentSignal.topic(PaymentEvent.CREDIT_APPROVED));
    assertEquals(PaymentSignal.CREDIT, PaymentSignal.topic(PaymentEvent.CREDIT_REJECTED));
    assertEquals(PaymentSignal.REVERSAL, PaymentSignal.topic(PaymentEvent.REVERSAL_APPROVED));
    assertEquals(PaymentSignal.REVERSAL, PaymentSignal.topic(PaymentEvent.REVERSAL_REJECTED));
  }

  @Test
  void leavesSwitchEventsToTheWorkflow() {
    assertNull(PaymentSignal.topic(PaymentEvent.VPA_RESOLVED));
    assertNull(PaymentSignal.topic(PaymentEvent.VPA_UNRESOLVED));
    assertNull(PaymentSignal.topic(PaymentEvent.CREDIT_REQUESTED));
    assertNull(PaymentSignal.topic(PaymentEvent.PARTIES_ADVISED));
  }
}

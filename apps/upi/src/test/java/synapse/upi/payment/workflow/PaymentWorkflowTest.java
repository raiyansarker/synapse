package synapse.upi.payment.workflow;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import dev.dbos.transact.DBOS;
import dev.dbos.transact.StartWorkflowOptions;
import dev.dbos.transact.execution.ThrowingSupplier;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import synapse.upi.payment.Payment;
import synapse.upi.payment.statemachine.PaymentEvent;
import synapse.upi.payment.statemachine.PaymentState;

@ExtendWith(MockitoExtension.class)
class PaymentWorkflowTest {

  @Mock private DBOS dbos;

  @Test
  void startUsesTheAtomicIdAsTheWorkflowId() {
    PaymentWorkflow workflow = new PaymentWorkflow(null, dbos);
    Payment payment = Payment.accept("mina@city", "raiyan@city", new BigDecimal("10.00"));

    assertSame(payment, workflow.start(payment));

    ArgumentCaptor<StartWorkflowOptions> options =
        ArgumentCaptor.forClass(StartWorkflowOptions.class);
    verify(dbos)
        .startWorkflow(
            org.mockito.ArgumentMatchers.<ThrowingSupplier<PaymentState, Exception>>any(),
            options.capture());
    assertEquals(payment.atomicId(), options.getValue().workflowId());
  }

  @Test
  void signalDeliversABankReplyOnce() {
    PaymentWorkflow workflow = new PaymentWorkflow(null, dbos);

    workflow.signal("pay-1", PaymentEvent.DEBIT_APPROVED);

    verify(dbos).send("pay-1", "DEBIT_APPROVED", PaymentSignal.DEBIT, "pay-1:DEBIT_APPROVED");
  }

  @Test
  void signalRefusesAnEventTheWorkflowAppliesItself() {
    PaymentWorkflow workflow = new PaymentWorkflow(null, dbos);

    IllegalArgumentException error =
        assertThrows(
            IllegalArgumentException.class,
            () -> workflow.signal("pay-1", PaymentEvent.VPA_RESOLVED));

    assertEquals("VPA_RESOLVED is applied by the workflow", error.getMessage());
    verifyNoInteractions(dbos);
  }
}

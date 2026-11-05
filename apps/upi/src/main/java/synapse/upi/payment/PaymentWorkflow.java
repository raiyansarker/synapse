package synapse.upi.payment;

import dev.dbos.transact.DBOS;
import dev.dbos.transact.StartWorkflowOptions;
import dev.dbos.transact.workflow.Step;
import dev.dbos.transact.workflow.Workflow;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

/**
 * One DBOS workflow per payment. The workflow id is the atomic id. Completed steps are checkpointed
 * in the {@code dbos} schema of the application database, so a restart continues from the last one.
 */
@Service
public class PaymentWorkflow {

  private static final Duration BANK_WAIT = Duration.ofHours(24);

  private final PaymentStateMachine states;
  private final DBOS dbos;
  private PaymentWorkflow self;

  public PaymentWorkflow(PaymentStateMachine states, DBOS dbos) {
    this.states = states;
    this.dbos = dbos;
  }

  @Autowired
  void setSelf(@Lazy PaymentWorkflow self) {
    this.self = self;
  }

  public Payment start(
      String payerVirtualAddress,
      String payeeVirtualAddress,
      BigDecimal amount,
      Map<String, String> metadata) {
    Payment payment = Payment.accept(payerVirtualAddress, payeeVirtualAddress, amount, metadata);
    dbos.startWorkflow(
        () -> self.run(
            payment.atomicId(),
            payment.payerVirtualAddress(),
            payment.payeeVirtualAddress(),
            payment.amount(),
            payment.metadata()),
        new StartWorkflowOptions(payment.atomicId()));
    return payment;
  }

  public void signal(String atomicId, PaymentEvent event) {
    String topic = PaymentSignal.topic(event);
    if (topic == null) {
      throw new IllegalArgumentException(event + " is applied by the workflow");
    }
    dbos.send(atomicId, event.name(), topic, atomicId + ":" + event.name());
  }

  @Workflow
  public PaymentState run(
      String atomicId,
      String payerVirtualAddress,
      String payeeVirtualAddress,
      BigDecimal amount,
      Map<String, String> metadata) {
    Payment payment = new Payment(
        atomicId,
        PaymentState.ACCEPTED,
        payerVirtualAddress,
        payeeVirtualAddress,
        amount,
        metadata);
    if (!self.resolve(payment)) {
      payment = payment.withState(self.apply(payment, PaymentEvent.VPA_UNRESOLVED));
      self.reportToPayee(payment);
      return payment.state();
    }
    payment = payment.withState(self.apply(payment, PaymentEvent.VPA_RESOLVED));

    payment = payment.withState(self.apply(payment, awaitBank(PaymentSignal.DEBIT)));
    if (payment.state() != PaymentState.AUTHORIZED) {
      self.reportToPayee(payment);
      return payment.state();
    }

    self.requestCredit(payment);
    payment = payment.withState(self.apply(payment, PaymentEvent.CREDIT_REQUESTED));
    PaymentEvent credit = awaitBank(PaymentSignal.CREDIT);
    payment = payment.withState(self.apply(payment, credit));
    if (credit == PaymentEvent.CREDIT_APPROVED) {
      if (self.acknowledgePayer(payment)) {
        return self.apply(payment, PaymentEvent.PAYER_ACKNOWLEDGED);
      }
      payment = payment.withState(self.apply(payment, PaymentEvent.PAYER_ACK_FAILED));
      self.requestReversal(payment);
      return self.apply(payment, awaitBank(PaymentSignal.REVERSAL));
    }

    self.requestReversal(payment);
    return self.apply(payment, awaitBank(PaymentSignal.REVERSAL));
  }

  /**
   * Resolves both virtual addresses and, when they resolve, asks the payer's bank for the debit.
   * A directory and the bank call replace this body. The step boundary is what must stay.
   */
  @Step
  public boolean resolve(Payment payment) {
    return true;
  }

  /** Asks the payee's bank to credit the payee. */
  @Step
  public void requestCredit(Payment payment) {}

  /**
   * Asks the payer's bank to reverse the debit. Sent when the payee's bank rejects the credit, and
   * when the payer acknowledgement fails after the credit has already succeeded.
   */
  @Step
  public void requestReversal(Payment payment) {}

  /**
   * Tells the payer's bank the credit succeeded. Returns false when that acknowledgement fails.
   * The workflow then sends a reversal. A thrown exception is a crash, not a failed acknowledgement.
   */
  @Step
  public boolean acknowledgePayer(Payment payment) {
    return true;
  }

  /** Tells the payee's bank the request ended before a credit. The payee bank notifies its user. */
  @Step(maxAttempts = 25, intervalSeconds = 5, backOffRate = 2)
  public void reportToPayee(Payment payment) {}

  @Step
  public PaymentState apply(Payment payment, PaymentEvent event) {
    return states.apply(payment, event).state();
  }

  private PaymentEvent awaitBank(String topic) {
    while (true) {
      Optional<String> message = dbos.recv(topic, BANK_WAIT);
      if (message.isPresent()) {
        return PaymentEvent.valueOf(message.get());
      }
    }
  }
}

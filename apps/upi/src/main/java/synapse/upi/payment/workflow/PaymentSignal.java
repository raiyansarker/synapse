package synapse.upi.payment.workflow;

import synapse.upi.payment.statemachine.PaymentEvent;

/**
 * Bank replies that a running payment workflow can receive. The workflow itself applies every other
 * event.
 */
public final class PaymentSignal {

  public static final String DEBIT = "debit";
  public static final String CREDIT = "credit";
  public static final String REVERSAL = "reversal";

  private PaymentSignal() {}

  public static String topic(PaymentEvent event) {
    return switch (event) {
      case DEBIT_APPROVED, DEBIT_DECLINED -> DEBIT;
      case CREDIT_APPROVED, CREDIT_REJECTED -> CREDIT;
      case REVERSAL_APPROVED, REVERSAL_REJECTED -> REVERSAL;
      default -> null;
    };
  }
}

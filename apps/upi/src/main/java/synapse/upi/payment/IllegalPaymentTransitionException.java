package synapse.upi.payment;

public class IllegalPaymentTransitionException extends RuntimeException {

  private final PaymentState state;
  private final PaymentEvent event;

  public IllegalPaymentTransitionException(PaymentState state, PaymentEvent event) {
    super("Cannot apply " + event + " while payment is " + state);
    this.state = state;
    this.event = event;
  }

  public PaymentState state() {
    return state;
  }

  public PaymentEvent event() {
    return event;
  }
}

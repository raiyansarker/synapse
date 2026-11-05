package synapse.upi.payment.statemachine;

import static synapse.upi.payment.statemachine.PaymentEvent.CREDIT_APPROVED;
import static synapse.upi.payment.statemachine.PaymentEvent.CREDIT_REJECTED;
import static synapse.upi.payment.statemachine.PaymentEvent.CREDIT_REQUESTED;
import static synapse.upi.payment.statemachine.PaymentEvent.DEBIT_APPROVED;
import static synapse.upi.payment.statemachine.PaymentEvent.DEBIT_DECLINED;
import static synapse.upi.payment.statemachine.PaymentEvent.PAYER_ACKNOWLEDGED;
import static synapse.upi.payment.statemachine.PaymentEvent.PAYER_ACK_FAILED;
import static synapse.upi.payment.statemachine.PaymentEvent.REVERSAL_APPROVED;
import static synapse.upi.payment.statemachine.PaymentEvent.REVERSAL_REJECTED;
import static synapse.upi.payment.statemachine.PaymentEvent.VPA_RESOLVED;
import static synapse.upi.payment.statemachine.PaymentEvent.VPA_UNRESOLVED;
import static synapse.upi.payment.statemachine.PaymentState.ACCEPTED;
import static synapse.upi.payment.statemachine.PaymentState.ACKNOWLEDGING;
import static synapse.upi.payment.statemachine.PaymentState.AUTHORIZATION_PENDING;
import static synapse.upi.payment.statemachine.PaymentState.AUTHORIZED;
import static synapse.upi.payment.statemachine.PaymentState.COMPLETED;
import static synapse.upi.payment.statemachine.PaymentState.CREDIT_PENDING;
import static synapse.upi.payment.statemachine.PaymentState.DECLINED;
import static synapse.upi.payment.statemachine.PaymentState.RESOLUTION_FAILED;
import static synapse.upi.payment.statemachine.PaymentState.REVERSAL_FAILED;
import static synapse.upi.payment.statemachine.PaymentState.REVERSAL_PENDING;
import static synapse.upi.payment.statemachine.PaymentState.REVERSED;

import java.util.EnumSet;
import org.springframework.context.annotation.Configuration;
import org.springframework.statemachine.config.EnableStateMachineFactory;
import org.springframework.statemachine.config.EnumStateMachineConfigurerAdapter;
import org.springframework.statemachine.config.builders.StateMachineConfigurationConfigurer;
import org.springframework.statemachine.config.builders.StateMachineStateConfigurer;
import org.springframework.statemachine.config.builders.StateMachineTransitionConfigurer;

/**
 * Allowed payment transitions. Each line is {@code from}, {@code event}, {@code to}.
 * See docs/payment-state-machine.md.
 */
@Configuration
@EnableStateMachineFactory(contextEvents = false)
public class PaymentStateMachineConfig
    extends EnumStateMachineConfigurerAdapter<PaymentState, PaymentEvent> {

  @Override
  public void configure(StateMachineConfigurationConfigurer<PaymentState, PaymentEvent> config)
      throws Exception {
    config.withConfiguration().autoStartup(false);
  }

  @Override
  public void configure(StateMachineStateConfigurer<PaymentState, PaymentEvent> states)
      throws Exception {
    var all = states.withStates().initial(ACCEPTED).states(EnumSet.allOf(PaymentState.class));
    for (PaymentState state : PaymentState.values()) {
      if (state.terminal()) {
        all.end(state);
      }
    }
  }

  @Override
  public void configure(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    resolution(transitions);
    debit(transitions);
    credit(transitions);
    acknowledgement(transitions);
    reversal(transitions);
  }

  /** The payee's request either finds the payer's bank or ends. */
  private void resolution(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    allow(transitions, ACCEPTED, VPA_RESOLVED, AUTHORIZATION_PENDING);
    allow(transitions, ACCEPTED, VPA_UNRESOLVED, RESOLUTION_FAILED);
  }

  /** The payer's bank verifies the payment and either debits or refuses. */
  private void debit(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    allow(transitions, AUTHORIZATION_PENDING, DEBIT_APPROVED, AUTHORIZED);
    allow(transitions, AUTHORIZATION_PENDING, DEBIT_DECLINED, DECLINED);
  }

  /** After the debit, the payee's bank is asked to credit. */
  private void credit(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    allow(transitions, AUTHORIZED, CREDIT_REQUESTED, CREDIT_PENDING);
    allow(transitions, CREDIT_PENDING, CREDIT_APPROVED, ACKNOWLEDGING);
    allow(transitions, CREDIT_PENDING, CREDIT_REJECTED, REVERSAL_PENDING);
  }

  /** The credit succeeded. The payer's bank is told, or the acknowledgement fails. */
  private void acknowledgement(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    allow(transitions, ACKNOWLEDGING, PAYER_ACKNOWLEDGED, COMPLETED);
    allow(transitions, ACKNOWLEDGING, PAYER_ACK_FAILED, REVERSAL_PENDING);
  }

  /** The debit must be undone, whether the credit was rejected or the acknowledgement failed. */
  private void reversal(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    allow(transitions, REVERSAL_PENDING, REVERSAL_APPROVED, REVERSED);
    allow(transitions, REVERSAL_PENDING, REVERSAL_REJECTED, REVERSAL_FAILED);
  }

  private void allow(
      StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions,
      PaymentState from,
      PaymentEvent event,
      PaymentState to)
      throws Exception {
    transitions.withExternal().source(from).event(event).target(to);
  }
}

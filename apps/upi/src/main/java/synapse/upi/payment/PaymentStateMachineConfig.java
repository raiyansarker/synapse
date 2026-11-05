package synapse.upi.payment;

import java.util.EnumSet;
import org.springframework.context.annotation.Configuration;
import org.springframework.statemachine.config.EnableStateMachineFactory;
import org.springframework.statemachine.config.EnumStateMachineConfigurerAdapter;
import org.springframework.statemachine.config.builders.StateMachineConfigurationConfigurer;
import org.springframework.statemachine.config.builders.StateMachineStateConfigurer;
import org.springframework.statemachine.config.builders.StateMachineTransitionConfigurer;

/**
 * Spring Statemachine definition of a switch payment. Each payment gets its own machine from the
 * factory. See docs/payment-state-machine.md.
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
    states
        .withStates()
        .initial(PaymentState.ACCEPTED)
        .end(PaymentState.COMPLETED)
        .end(PaymentState.RESOLUTION_FAILED)
        .end(PaymentState.DECLINED)
        .end(PaymentState.REVERSED)
        .end(PaymentState.REVERSAL_FAILED)
        .states(EnumSet.allOf(PaymentState.class));
  }

  @Override
  public void configure(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
      throws Exception {
    transitions
        .withExternal()
        .source(PaymentState.ACCEPTED)
        .target(PaymentState.AUTHORIZATION_PENDING)
        .event(PaymentEvent.VPA_RESOLVED)
        .and()
        .withExternal()
        .source(PaymentState.ACCEPTED)
        .target(PaymentState.RESOLUTION_FAILED)
        .event(PaymentEvent.VPA_UNRESOLVED)
        .and()
        .withExternal()
        .source(PaymentState.AUTHORIZATION_PENDING)
        .target(PaymentState.AUTHORIZED)
        .event(PaymentEvent.DEBIT_APPROVED)
        .and()
        .withExternal()
        .source(PaymentState.AUTHORIZATION_PENDING)
        .target(PaymentState.DECLINED)
        .event(PaymentEvent.DEBIT_DECLINED)
        .and()
        .withExternal()
        .source(PaymentState.AUTHORIZED)
        .target(PaymentState.CREDIT_PENDING)
        .event(PaymentEvent.CREDIT_REQUESTED)
        .and()
        .withExternal()
        .source(PaymentState.CREDIT_PENDING)
        .target(PaymentState.ACKNOWLEDGING)
        .event(PaymentEvent.CREDIT_APPROVED)
        .and()
        .withExternal()
        .source(PaymentState.CREDIT_PENDING)
        .target(PaymentState.REVERSAL_PENDING)
        .event(PaymentEvent.CREDIT_REJECTED)
        .and()
        .withExternal()
        .source(PaymentState.ACKNOWLEDGING)
        .target(PaymentState.COMPLETED)
        .event(PaymentEvent.PAYER_ACKNOWLEDGED)
        .and()
        .withExternal()
        .source(PaymentState.REVERSAL_PENDING)
        .target(PaymentState.REVERSED)
        .event(PaymentEvent.REVERSAL_APPROVED)
        .and()
        .withExternal()
        .source(PaymentState.REVERSAL_PENDING)
        .target(PaymentState.REVERSAL_FAILED)
        .event(PaymentEvent.REVERSAL_REJECTED);
  }
}

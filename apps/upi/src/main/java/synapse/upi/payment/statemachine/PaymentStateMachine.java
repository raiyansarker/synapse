package synapse.upi.payment.statemachine;

import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.statemachine.StateMachine;
import org.springframework.statemachine.StateMachineEventResult;
import org.springframework.statemachine.StateMachineEventResult.ResultType;
import org.springframework.statemachine.config.StateMachineFactory;
import org.springframework.statemachine.support.DefaultStateMachineContext;
import org.springframework.statemachine.transition.Transition;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import synapse.upi.payment.Payment;

/**
 * Runs one Spring Statemachine per transition. The payment's stored state is restored before the
 * event is sent, so two payments never share a machine.
 */
@Component
public class PaymentStateMachine {

  private final StateMachineFactory<PaymentState, PaymentEvent> machines;

  public PaymentStateMachine(StateMachineFactory<PaymentState, PaymentEvent> machines) {
    this.machines = machines;
  }

  public Payment apply(Payment payment, PaymentEvent event) {
    return payment.withState(transit(payment.state(), event));
  }

  public PaymentState transit(PaymentState state, PaymentEvent event) {
    return withMachine(state, machine -> {
      List<StateMachineEventResult<PaymentState, PaymentEvent>> results = machine
          .sendEventCollect(Mono.just(MessageBuilder.withPayload(event).build()))
          .block();
      boolean accepted = results != null
          && results.stream().anyMatch(result -> result.getResultType() == ResultType.ACCEPTED);
      if (!accepted) {
        throw new IllegalPaymentTransitionException(state, event);
      }
      return machine.getState().getId();
    });
  }

  public Set<PaymentEvent> eventsFrom(PaymentState state) {
    return withMachine(state, machine -> machine.getTransitions().stream()
        .filter(transition -> transition.getSource().getId() == state)
        .map(Transition::getTrigger)
        .filter(Objects::nonNull)
        .map(trigger -> trigger.getEvent())
        .filter(Objects::nonNull)
        .collect(Collectors.toUnmodifiableSet()));
  }

  private <T> T withMachine(
      PaymentState state, Function<StateMachine<PaymentState, PaymentEvent>, T> action) {
    StateMachine<PaymentState, PaymentEvent> machine = machines.getStateMachine();
    try {
      machine.stopReactively().block();
      machine
          .getStateMachineAccessor()
          .doWithAllRegions(access -> access
              .resetStateMachineReactively(new DefaultStateMachineContext<>(state, null, null, null))
              .block());
      machine.startReactively().block();
      return action.apply(machine);
    } finally {
      machine.stopReactively().block();
    }
  }
}

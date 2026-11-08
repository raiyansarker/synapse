package synapse.upi.pay.ack.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.ack.interfaces.AckGateway;
import synapse.upi.pay.ack.interfaces.AckResult;
import synapse.upi.pay.mock.MockOutcomes;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "upi.ack.mock", havingValue = "true", matchIfMissing = true)
public class MockAckGateway implements AckGateway {

  private final MockOutcomes outcomes;

  @Override
  public AckResult acknowledge(Ledger entry) {
    outcomes.pause();
    return switch (outcomes.getAck()) {
      case APPROVE -> {
        log.info("[MOCK] Ack succeeded id={}", entry.getId());
        yield new AckResult.Succeeded();
      }
      case DECLINE -> {
        log.info("[MOCK] Ack failed id={}", entry.getId());
        yield new AckResult.Failed("NOTIFY_REJECTED");
      }
      case TRANSIENT -> throw new RuntimeException(
          "Simulated ack timeout for id=" + entry.getId());
    };
  }
}

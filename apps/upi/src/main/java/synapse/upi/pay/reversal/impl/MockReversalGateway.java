package synapse.upi.pay.reversal.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.mock.MockOutcomes;
import synapse.upi.pay.reversal.interfaces.ReversalGateway;
import synapse.upi.pay.reversal.interfaces.ReversalResult;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "upi.reversal.mock", havingValue = "true", matchIfMissing = true)
public class MockReversalGateway implements ReversalGateway {

  private final MockOutcomes outcomes;

  @Override
  public ReversalResult reverse(Ledger entry) {
    outcomes.pause();
    return switch (outcomes.getReversal()) {
      case APPROVE -> {
        log.info("[MOCK] Reversal succeeded id={} sva={} amount={}",
            entry.getId(), entry.getSva(), entry.getAmount());
        yield new ReversalResult.Reversed();
      }
      case DECLINE -> {
        log.info("[MOCK] Reversal failed id={} sva={}", entry.getId(), entry.getSva());
        yield new ReversalResult.Failed("REVERSE_REJECTED");
      }
      case TRANSIENT -> throw new RuntimeException(
          "Simulated bank timeout for sva=" + entry.getSva());
    };
  }
}

package synapse.upi.pay.debit.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.debit.interfaces.DebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;
import synapse.upi.pay.mock.MockOutcomes;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "upi.debit.mock", havingValue = "true", matchIfMissing = true)
public class MockDebitGateway implements DebitGateway {

  private final MockOutcomes outcomes;

  @Override
  public DebitResult debit(Ledger entry) {
    outcomes.pause();
    return switch (outcomes.getDebit()) {
      case APPROVE -> {
        log.info("[MOCK] Debit approved id={} sva={} amount={}",
            entry.getId(), entry.getSva(), entry.getAmount());
        yield new DebitResult.Approved();
      }
      case DECLINE -> {
        log.info("[MOCK] Debit declined id={} sva={} amount={}",
            entry.getId(), entry.getSva(), entry.getAmount());
        yield new DebitResult.Declined("INSUFFICIENT_FUNDS");
      }
      case TRANSIENT -> throw new RuntimeException(
          "Simulated bank timeout for sva=" + entry.getSva());
    };
  }
}

package synapse.upi.pay.credit.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.credit.interfaces.CreditGateway;
import synapse.upi.pay.credit.interfaces.CreditResult;
import synapse.upi.pay.mock.MockOutcomes;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "upi.credit.mock", havingValue = "true", matchIfMissing = true)
public class MockCreditGateway implements CreditGateway {

  private final MockOutcomes outcomes;

  @Override
  public CreditResult credit(Ledger entry) {
    outcomes.pause();
    return switch (outcomes.getCredit()) {
      case APPROVE -> {
        log.info("[MOCK] Credit approved id={} rva={} amount={}",
            entry.getId(), entry.getRva(), entry.getAmount());
        yield new CreditResult.Approved();
      }
      case DECLINE -> {
        log.info("[MOCK] Credit declined id={} rva={} amount={}",
            entry.getId(), entry.getRva(), entry.getAmount());
        yield new CreditResult.Declined("ACCOUNT_CLOSED");
      }
      case TRANSIENT -> throw new RuntimeException(
          "Simulated bank timeout for rva=" + entry.getRva());
    };
  }
}

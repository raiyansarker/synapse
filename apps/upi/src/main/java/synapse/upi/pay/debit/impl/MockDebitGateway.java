package synapse.upi.pay.debit.impl;

import java.util.concurrent.ThreadLocalRandom;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.debit.interfaces.DebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;

@Slf4j
@Component
@ConditionalOnProperty(name = "upi.debit.mock", havingValue = "true", matchIfMissing = true)
public class MockDebitGateway implements DebitGateway {

  private static final double TRANSIENT_FAILURE_RATE = 0.3;
  private static final double DECLINE_RATE = 0.1;

  @Override
  public DebitResult debit(Ledger entry) {
    double roll = ThreadLocalRandom.current().nextDouble();

    if (roll < TRANSIENT_FAILURE_RATE) {
      log.warn("[MOCK] Simulated transient bank failure for id={} — triggering retry", entry.getId());
      throw new RuntimeException("Simulated bank timeout for sva=" + entry.getSva());
    }

    if (roll < TRANSIENT_FAILURE_RATE + DECLINE_RATE) {
      log.info("[MOCK] Debit declined id={} sva={} amount={}",
          entry.getId(), entry.getSva(), entry.getAmount());
      return new DebitResult.Declined("INSUFFICIENT_FUNDS");
    }

    log.info("[MOCK] Debit approved id={} sva={} amount={}",
        entry.getId(), entry.getSva(), entry.getAmount());
    return new DebitResult.Approved();
  }
}

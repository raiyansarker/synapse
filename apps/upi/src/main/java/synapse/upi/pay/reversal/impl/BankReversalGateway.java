package synapse.upi.pay.reversal.impl;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.reversal.interfaces.ReversalGateway;
import synapse.upi.pay.reversal.interfaces.ReversalResult;

@Component
@ConditionalOnProperty(name = "upi.reversal.mock", havingValue = "false")
public class BankReversalGateway implements ReversalGateway {

  @Override
  public ReversalResult reverse(Ledger entry) {
    throw new UnsupportedOperationException(
        "Bank reversal not yet implemented for sva=" + entry.getSva());
  }
}

package synapse.upi.pay.debit.impl;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.debit.interfaces.DebitGateway;
import synapse.upi.pay.debit.interfaces.DebitResult;

@Component
@ConditionalOnProperty(name = "upi.debit.mock", havingValue = "false")
public class BankDebitGateway implements DebitGateway {

  @Override
  public DebitResult debit(Ledger entry) {
    throw new UnsupportedOperationException(
        "Bank debit not yet implemented for sva=" + entry.getSva());
  }
}

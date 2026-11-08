package synapse.upi.pay.credit.impl;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.credit.interfaces.CreditGateway;
import synapse.upi.pay.credit.interfaces.CreditResult;

@Component
@ConditionalOnProperty(name = "upi.credit.mock", havingValue = "false")
public class BankCreditGateway implements CreditGateway {

  @Override
  public CreditResult credit(Ledger entry) {
    throw new UnsupportedOperationException(
        "Bank credit not yet implemented for rva=" + entry.getRva());
  }
}

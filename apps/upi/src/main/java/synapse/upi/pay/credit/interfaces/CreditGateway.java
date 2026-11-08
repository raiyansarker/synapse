package synapse.upi.pay.credit.interfaces;

import synapse.upi.ledger.Ledger;

public interface CreditGateway {

  /**
   * Request a credit to the receiver's bank.
   *
   * @return {@link CreditResult.Approved} or {@link CreditResult.Declined}
   * @throws RuntimeException on transient failures
   */
  CreditResult credit(Ledger entry);
}

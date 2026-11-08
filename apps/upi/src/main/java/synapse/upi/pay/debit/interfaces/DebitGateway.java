package synapse.upi.pay.debit.interfaces;

import synapse.upi.ledger.Ledger;

public interface DebitGateway {

  /**
   * Request a debit from the sender's bank.
   *
   * @return {@link DebitResult.Approved} or {@link DebitResult.Declined}
   * @throws RuntimeException on transient failures (timeout, network, unavailable)
   */
  DebitResult debit(Ledger entry);
}

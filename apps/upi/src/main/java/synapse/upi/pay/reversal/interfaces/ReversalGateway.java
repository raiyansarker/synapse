package synapse.upi.pay.reversal.interfaces;

import synapse.upi.ledger.Ledger;

public interface ReversalGateway {

  /**
   * Reverse the sender-bank debit for this payment.
   *
   * @return {@link ReversalResult.Reversed} or {@link ReversalResult.Failed}
   * @throws RuntimeException on transient failures
   */
  ReversalResult reverse(Ledger entry);
}

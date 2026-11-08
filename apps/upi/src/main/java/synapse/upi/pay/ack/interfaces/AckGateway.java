package synapse.upi.pay.ack.interfaces;

import synapse.upi.ledger.Ledger;

public interface AckGateway {

  /**
   * Notify the sender's bank that the payment settled (debit + credit done).
   *
   * @return {@link AckResult.Succeeded} or {@link AckResult.Failed}
   * @throws RuntimeException on transient failures
   */
  AckResult acknowledge(Ledger entry);
}

package synapse.upi.pay.ack.impl;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import synapse.upi.ledger.Ledger;
import synapse.upi.pay.ack.interfaces.AckGateway;
import synapse.upi.pay.ack.interfaces.AckResult;

@Component
@ConditionalOnProperty(name = "upi.ack.mock", havingValue = "false")
public class BankAckGateway implements AckGateway {

  @Override
  public AckResult acknowledge(Ledger entry) {
    throw new UnsupportedOperationException(
        "Bank acknowledgment not yet implemented for sva=" + entry.getSva());
  }
}

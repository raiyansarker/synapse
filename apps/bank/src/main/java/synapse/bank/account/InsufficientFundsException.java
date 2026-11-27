package synapse.bank.account;

import java.math.BigDecimal;
import lombok.Getter;

@Getter
public class InsufficientFundsException extends RuntimeException {

  private final String virtualAddress;
  private final BigDecimal balance;
  private final BigDecimal requested;

  public InsufficientFundsException(
      String virtualAddress,
      BigDecimal balance,
      BigDecimal requested
  ) {
    super(
        "account "
            + virtualAddress
            + " holds "
            + balance
            + " but "
            + requested
            + " was requested");
    this.virtualAddress = virtualAddress;
    this.balance = balance;
    this.requested = requested;
  }
}

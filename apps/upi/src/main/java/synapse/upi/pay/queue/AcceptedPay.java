package synapse.upi.pay.queue;

import java.math.BigDecimal;

public record AcceptedPay(
  String id,
  String sva,
  BigDecimal amount,
  String rva
) {}

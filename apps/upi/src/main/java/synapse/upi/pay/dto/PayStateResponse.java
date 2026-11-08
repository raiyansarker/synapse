package synapse.upi.pay.dto;

import synapse.upi.ledger.PaymentState;

public record PayStateResponse(
  PaymentState state
) {}

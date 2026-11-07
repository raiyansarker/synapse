package synapse.upi.pay.dto;

public record AcceptPayResponse(
  String idempotencyKey
) {}

package synapse.upi.admin.dto;

import java.math.BigDecimal;
import java.time.Instant;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.PaymentState;

public record AdminPaymentDto(
    String id,
    String sva,
    String rva,
    BigDecimal amount,
    PaymentState state,
    Instant createdAt,
    Instant updatedAt
) {
  public static AdminPaymentDto from(Ledger ledger) {
    return new AdminPaymentDto(
        ledger.getId(),
        ledger.getSva(),
        ledger.getRva(),
        ledger.getAmount(),
        ledger.getState(),
        ledger.getCreatedAt(),
        ledger.getUpdatedAt()
    );
  }
}

package synapse.bank.ledger.dto;

import java.math.BigDecimal;
import java.time.Instant;
import synapse.bank.ledger.EntryType;

public record LedgerResponse(
    String id,
    EntryType type,
    BigDecimal amount,
    BigDecimal balanceAfter,
    String reference,
    Instant createdAt
) {}

package synapse.bank.account.dto;

import java.math.BigDecimal;
import synapse.bank.account.AccountStatus;

public record AccountResponse(String virtualAddress, BigDecimal balance, AccountStatus status) {}

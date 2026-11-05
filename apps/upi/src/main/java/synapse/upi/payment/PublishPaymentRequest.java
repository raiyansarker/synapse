package synapse.upi.payment;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

/**
 * Body of {@code POST /payments}.
 *
 * @param sva sender virtual address, {@code name@bank}. The address the money leaves.
 * @param amount the amount that moves
 * @param rva receiver virtual address, {@code name@bank}. The ledger uses this to find the receiver's bank.
 */
public record PublishPaymentRequest(
    @NotBlank @Va String sva,
    @NotNull @Positive BigDecimal amount,
    @NotBlank @Va String rva) {}

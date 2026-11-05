package synapse.upi.payment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import synapse.common.validation.VirtualAddress;

/**
 * Body of {@code POST /api/pay}.
 *
 * @param sva sender virtual address, {@code name@bank}. The address the money leaves.
 * @param amount the amount that moves
 * @param rva receiver virtual address, {@code name@bank}. The ledger uses this to find the
 *     receiver's bank.
 */
public record PublishPaymentRequest(
    @NotBlank @VirtualAddress String sva,
    @NotNull @Positive BigDecimal amount,
    @NotBlank @VirtualAddress String rva) {}

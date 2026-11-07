package synapse.upi.pay.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import synapse.common.validation.VirtualAddress;

public record AcceptPayRequest(
  @NotBlank
  @VirtualAddress
  String sva,

  @NotNull
  @DecimalMin("0.01")
  @DecimalMax("1000000.00")
  @Digits(integer = 7, fraction = 2)
  BigDecimal amount,

  @NotBlank
  @VirtualAddress
  String rva
) {}

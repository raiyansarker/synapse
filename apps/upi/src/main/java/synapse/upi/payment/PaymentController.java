package synapse.upi.payment;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.common.exception.BadRequestException;

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

  private final PaymentWorkflow payments;

  @PostMapping
  public AcceptedPayment publish(@Valid @RequestBody PublishPaymentRequest request) {
    requireVirtualAddress(request.virtualAddress(), "virtualAddress");
    requireVirtualAddress(request.payeeVirtualAddress(), "payeeVirtualAddress");
    Payment payment = payments.start(
        request.virtualAddress(),
        request.payeeVirtualAddress(),
        request.amount(),
        request.metadata());
    return new AcceptedPayment(payment.atomicId());
  }

  private static void requireVirtualAddress(String value, String field) {
    int at = value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
      throw new BadRequestException(
          "Validation failed",
          List.of(Map.of("field", field, "message", "must look like name@bank")));
    }
  }

  public record PublishPaymentRequest(
      @NotBlank String virtualAddress,
      @NotNull @Positive BigDecimal amount,
      @NotBlank String payeeVirtualAddress,
      Map<String, String> metadata) {}

  public record AcceptedPayment(String atomicId) {}
}

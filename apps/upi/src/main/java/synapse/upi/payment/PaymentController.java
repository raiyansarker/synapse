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
    requireVa(request.payerVa(), "payerVa");
    requireVa(request.payeeVa(), "payeeVa");
    Payment payment = payments.start(request.payerVa(), request.payeeVa(), request.amount());
    return new AcceptedPayment(payment.atomicId());
  }

  private static void requireVa(String value, String field) {
    int at = value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
      throw new BadRequestException(
          "Validation failed",
          List.of(Map.of("field", field, "message", "must look like name@bank")));
    }
  }

  public record PublishPaymentRequest(
      @NotBlank String payerVa,
      @NotNull @Positive BigDecimal amount,
      @NotBlank String payeeVa) {}

  public record AcceptedPayment(String atomicId) {}
}

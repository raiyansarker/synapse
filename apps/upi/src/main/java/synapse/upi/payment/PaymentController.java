package synapse.upi.payment;

import jakarta.validation.Valid;
import synapse.upi.payment.workflow.PaymentWorkflow;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

  private final PaymentWorkflow payments;

  @PostMapping
  public AcceptedPayment publish(@Valid @RequestBody PublishPaymentRequest request) {
    Payment payment = payments.start(Payment.accept(request.sva(), request.rva(), request.amount()));
    return new AcceptedPayment(payment.atomicId());
  }
}

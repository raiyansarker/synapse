package synapse.upi.payment.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.upi.payment.Payment;
import synapse.upi.payment.dto.AcceptedPayment;
import synapse.upi.payment.dto.PublishPaymentRequest;
import synapse.upi.payment.workflow.PaymentWorkflow;

@RestController
@RequestMapping("/api/pay")
@RequiredArgsConstructor
public class PaymentController {

  private final PaymentWorkflow payments;

  @PostMapping
  public AcceptedPayment publish(@Valid @RequestBody PublishPaymentRequest request) {
    Payment payment =
        payments.start(Payment.accept(request.sva(), request.rva(), request.amount()));
    return new AcceptedPayment(payment.atomicId());
  }
}

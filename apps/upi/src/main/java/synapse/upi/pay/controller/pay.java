package synapse.upi.pay.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.upi.ledger.Ledger;
import synapse.upi.ledger.LedgerRepository;
import synapse.upi.pay.queue.AcceptedPay;
import synapse.upi.pay.queue.PayProducer;
import synapse.upi.pay.dto.AcceptPayRequest;
import synapse.upi.pay.dto.AcceptPayResponse;

@RestController
@RequestMapping("/api/pay")
@RequiredArgsConstructor
public class Pay {
  private final LedgerRepository ledgerRepository;
  private final PayProducer pays;

  /**
   * Job is to accept a payment request in the ledger push it to the queue and send an idempotency
   * key
   */
  @PostMapping
  public AcceptPayResponse acceptPay(
      @Valid
      @RequestBody
      AcceptPayRequest request
  ) {
    /**
     * TODO: check for banks
     */

    Ledger transaction = Ledger.accepted(
        request.sva(),
        request.rva(),
        request.amount()
    );
    ledgerRepository.save(transaction);

    pays.publish(
        new AcceptedPay(
            transaction.getId(),
            transaction.getSva(),
            transaction.getAmount(),
            transaction.getRva()
        )
    );

      return new AcceptPayResponse(transaction.getId());
  }

  /** get the payment from the ledger using id */
  @GetMapping("{id}")
  public void getPayStatus(
      @PathVariable
      String id
  ) {
    throw new UnsupportedOperationException("not implemented");
  }
}

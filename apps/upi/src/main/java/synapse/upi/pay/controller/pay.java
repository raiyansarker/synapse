package synapse.upi.pay.controller;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.common.VirtualAddress;
import synapse.common.exception.NotFoundException;
import synapse.upi.bank.BankService;
import synapse.upi.pay.PayService;
import synapse.upi.pay.dto.AcceptPayRequest;
import synapse.upi.pay.dto.AcceptPayResponse;

@RestController
@RequestMapping("/api/pay")
@RequiredArgsConstructor
public class Pay {
  private final PayService payService;
  private final BankService bankService;

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

    VirtualAddress sva = VirtualAddress.parse(request.sva());
    VirtualAddress rva = VirtualAddress.parse(request.rva());
    Optional.of(List.of(sva.bankIdentifier(), rva.bankIdentifier()))
        .filter(bankService::exist)
        .orElseThrow(() -> new NotFoundException("bank was not found"));

    return new AcceptPayResponse(payService.accept(request));
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

package synapse.bank.account.controller;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.bank.account.AccountService;
import synapse.bank.account.dto.AccountResponse;
import synapse.bank.ledger.dto.LedgerResponse;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class Accounts {

  private final AccountService accountService;

  @GetMapping("/{virtualAddress}")
  public AccountResponse get(
      @PathVariable
      String virtualAddress
  ) {
    return this.accountService.getAccount(virtualAddress);
  }

  @GetMapping("/{virtualAddress}/ledger")
  public List<LedgerResponse> ledger(
      @PathVariable
      String virtualAddress
  ) {
    return this.accountService.getLedger(virtualAddress);
  }

  @PostMapping("/{virtualAddress}/freeze")
  public AccountResponse freeze(
      @PathVariable
      String virtualAddress
  ) {
    return this.accountService.freeze(virtualAddress);
  }

  @PostMapping("/{virtualAddress}/unfreeze")
  public AccountResponse unfreeze(
      @PathVariable
      String virtualAddress
  ) {
    return this.accountService.unfreeze(virtualAddress);
  }

  @PostMapping("/{virtualAddress}/close")
  public AccountResponse close(
      @PathVariable
      String virtualAddress
  ) {
    return this.accountService.close(virtualAddress);
  }
}

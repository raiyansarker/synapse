package synapse.bank.account;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import synapse.bank.account.dto.AccountResponse;
import synapse.bank.ledger.Ledger;
import synapse.bank.ledger.LedgerRepository;
import synapse.bank.ledger.dto.LedgerResponse;
import synapse.common.exception.NotFoundException;

@Service
@RequiredArgsConstructor
public class AccountService {
  private final AccountRepository accounts;
  private final LedgerRepository ledger;

  public AccountResponse getAccount(String virtualAddress) {
    return toResponse(findAccount(virtualAddress));
  }

  public List<LedgerResponse> getLedger(String virtualAddress) {
    Account account = findAccount(virtualAddress);
    return this.ledger.findByAccountIdOrderByCreatedAtDesc(account.getId()).stream()
        .map(AccountService::toResponse)
        .toList();
  }

  @Transactional
  public AccountResponse freeze(String virtualAddress) {
    Account account = findAccount(virtualAddress);
    account.freeze();
    return toResponse(this.accounts.save(account));
  }

  @Transactional
  public AccountResponse unfreeze(String virtualAddress) {
    Account account = findAccount(virtualAddress);
    account.unfreeze();
    return toResponse(this.accounts.save(account));
  }

  @Transactional
  public AccountResponse close(String virtualAddress) {
    Account account = findAccount(virtualAddress);
    account.close();
    return toResponse(this.accounts.save(account));
  }

  private Account findAccount(String virtualAddress) {
    return this.accounts
        .findByVirtualAddress(virtualAddress)
        .orElseThrow(
            () ->
                new NotFoundException(
                    "Account not found", "No account exists for " + virtualAddress));
  }

  private static AccountResponse toResponse(Account account) {
    return new AccountResponse(account.getVirtualAddress(), account.getBalance(), account.getStatus());
  }

  private static LedgerResponse toResponse(Ledger entry) {
    return new LedgerResponse(
        entry.getId(),
        entry.getType(),
        entry.getAmount(),
        entry.getBalanceAfter(),
        entry.getReference(),
        entry.getCreatedAt());
  }
}

package synapse.bank.ledger;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import synapse.bank.account.Account;

@Entity
@Table(name = "ledger")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Ledger {
  private static final BigDecimal CENT = new BigDecimal("0.01");

  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "account_id", nullable = false, updatable = false)
  private Account account;

  @Column(nullable = false, length = 32)
  private EntryType type;

  @Column(nullable = false, precision = 19, scale = 2)
  private BigDecimal amount;

  @Column(nullable = false, precision = 19, scale = 2)
  private BigDecimal balanceAfter;

  @Column(length = 64)
  private String reference;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  protected Ledger() {}

  private Ledger(
      String id,
      Account account,
      EntryType type,
      BigDecimal amount,
      BigDecimal balanceAfter,
      String reference
  ) {
    this.id = id;
    this.account = account;
    this.type = type;
    this.amount = amount;
    this.balanceAfter = balanceAfter;
    this.reference = reference;
  }

  public static Ledger credit(Account account, BigDecimal amount, String reference) {
    requireAccount(account);
    BigDecimal value = positive(amount);
    account.credit(value);
    return new Ledger(
        UUID.randomUUID().toString(), account, EntryType.CREDIT, value, account.getBalance(), reference);
  }

  public static Ledger debit(Account account, BigDecimal amount, String reference) {
    requireAccount(account);
    BigDecimal value = positive(amount);
    account.debit(value);
    return new Ledger(
        UUID.randomUUID().toString(), account, EntryType.DEBIT, value, account.getBalance(), reference);
  }

  private static void requireAccount(Account account) {
    if (account == null) {
      throw new IllegalArgumentException("account is required");
    }
  }

  private static BigDecimal positive(BigDecimal amount) {
    if (amount == null || amount.signum() <= 0) {
      throw new IllegalArgumentException("amount must be positive");
    }
    if (amount.remainder(CENT).signum() != 0) {
      throw new IllegalArgumentException("amount must be exact to 2 decimal places");
    }
    return amount;
  }
}

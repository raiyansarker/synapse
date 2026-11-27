package synapse.bank.account;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "accounts")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Account {
  private static final BigDecimal CENT = new BigDecimal("0.01");
  private static final Pattern USERNAME = Pattern.compile("[a-z0-9]+");

  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @Column(nullable = false, unique = true, length = 64)
  private String virtualAddress;

  @Column(nullable = false, precision = 19, scale = 2)
  private BigDecimal balance;

  @Column(nullable = false, length = 32)
  private AccountStatus status;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected Account() {}

  private Account(
      String id,
      String virtualAddress,
      BigDecimal balance,
      AccountStatus status
  ) {
    this.id = id;
    this.virtualAddress = virtualAddress;
    this.balance = balance;
    this.status = status;
  }

  public static Account open(String virtualAddress) {
    return open(virtualAddress, BigDecimal.ZERO);
  }

  public static Account open(String virtualAddress, BigDecimal initialBalance) {
    if (virtualAddress == null || !USERNAME.matcher(virtualAddress).matches()) {
      throw new IllegalArgumentException(
          "virtual address must be a username ([a-z0-9]+), e.g. \"raiyan\"");
    }
    if (initialBalance == null || initialBalance.signum() < 0) {
      throw new IllegalArgumentException("initial balance must not be negative");
    }
    return new Account(
        UUID.randomUUID().toString(),
        virtualAddress,
        exactToCents(initialBalance, "initial balance"),
        AccountStatus.ACTIVE);
  }

  public void credit(BigDecimal amount) {
    this.requireActive();
    this.balance = this.balance.add(positive(amount));
  }

  public void debit(BigDecimal amount) {
    this.requireActive();
    BigDecimal value = positive(amount);
    if (this.balance.compareTo(value) < 0) {
      throw new InsufficientFundsException(this.virtualAddress, this.balance, value);
    }
    this.balance = this.balance.subtract(value);
  }

  public void freeze() {
    this.requireNotClosed();
    this.status = AccountStatus.FROZEN;
  }

  public void unfreeze() {
    this.requireNotClosed();
    this.status = AccountStatus.ACTIVE;
  }

  public void close() {
    this.requireNotClosed();
    if (this.balance.signum() != 0) {
      throw new IllegalStateException(
          "cannot close " + this.virtualAddress + " with balance " + this.balance);
    }
    this.status = AccountStatus.CLOSED;
  }

  private void requireActive() {
    if (this.status != AccountStatus.ACTIVE) {
      throw new IllegalStateException("account " + this.virtualAddress + " is " + this.status);
    }
  }

  private void requireNotClosed() {
    if (this.status == AccountStatus.CLOSED) {
      throw new IllegalStateException("account " + this.virtualAddress + " is closed");
    }
  }

  private static BigDecimal positive(BigDecimal amount) {
    if (amount == null || amount.signum() <= 0) {
      throw new IllegalArgumentException("amount must be positive");
    }
    return exactToCents(amount, "amount");
  }

  private static BigDecimal exactToCents(BigDecimal value, String name) {
    if (value.remainder(CENT).signum() != 0) {
      throw new IllegalArgumentException(name + " must be exact to 2 decimal places");
    }
    return value;
  }
}

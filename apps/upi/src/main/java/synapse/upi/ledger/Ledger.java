package synapse.upi.ledger;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "ledger")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Ledger {
  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @Column(nullable = false, length = 320)
  private String sva;

  @Column(nullable = false, precision = 9, scale = 2)
  private BigDecimal amount;

  @Column(nullable = false, length = 320)
  private String rva;

  @Column(nullable = false, length = 32)
  private PaymentState state;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected Ledger() {}

  private Ledger(
      String id,
      String sva,
      String rva,
      BigDecimal amount,
      PaymentState state
  ) {
    this.id = id;
    this.sva = sva;
    this.amount = amount;
    this.rva = rva;
    this.state = state;
  }

  public static Ledger accepted(
      String sva,
      String rva,
      BigDecimal amount
  ) {
    return new Ledger(UUID.randomUUID().toString(), sva, rva, amount, PaymentState.ACCEPTED);
  }

  public void transitionTo(PaymentState state) {
    this.state = state;
  }

  public void markDebitAuthorizationPending() {
    this.state = PaymentState.DEBIT_AUTHORIZATION_PENDING;
  }

  public void markDebitAuthorized() {
    this.state = PaymentState.DEBIT_AUTHORIZED;
  }

  public void markDebitDeclined() {
    this.state = PaymentState.DEBIT_DECLINED;
  }

  public void markDebitAuthorizationFailed() {
    this.state = PaymentState.DEBIT_AUTHORIZATION_FAILED;
  }

  public void markCreditAuthorizationPending() {
    this.state = PaymentState.CREDIT_AUTHORIZATION_PENDING;
  }

  public void markCreditAuthorized() {
    this.state = PaymentState.CREDIT_AUTHORIZED;
  }

  public void markCreditAuthorizationFailed() {
    this.state = PaymentState.CREDIT_AUTHORIZATION_FAILED;
  }

  public void markAcknowledging() {
    this.state = PaymentState.ACKNOWLEDGING;
  }

  public void markCompleted() {
    this.state = PaymentState.COMPLETED;
  }

  public void markReversalPending() {
    this.state = PaymentState.REVERSAL_PENDING;
  }

  public void markReversed() {
    this.state = PaymentState.REVERSED;
  }

  public void markReversalFailed() {
    this.state = PaymentState.REVERSAL_FAILED;
  }
}

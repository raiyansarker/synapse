package synapse.upi.bank;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "banks")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Bank {
  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  /** Handle in {@code name@identifier}, {@code [a-z]+} only (e.g. {@code city}, {@code ucb}). */
  @Column(nullable = false, unique = true, length = 64)
  private String identifier;

  @Column(nullable = false, length = 2048)
  private String baseUrl;

  @Column(nullable = false)
  private boolean enabled;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected Bank() {}

  private Bank(
      String id,
      String identifier,
      String baseUrl,
      boolean enabled
  ) {
    this.id = id;
    this.identifier = identifier;
    this.baseUrl = baseUrl;
    this.enabled = enabled;
  }

  public static Bank create(
      String identifier,
      String baseUrl
  ) {
    return new Bank(UUID.randomUUID().toString(), identifier, baseUrl, true);
  }

  public void disable() {
    this.enabled = false;
  }

  public void enable() {
    this.enabled = true;
  }
}

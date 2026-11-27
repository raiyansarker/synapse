package synapse.bank.contact;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import synapse.bank.user.User;
import synapse.common.VirtualAddress;

@Entity
@Table(
    name = "contacts",
    uniqueConstraints = @UniqueConstraint(columnNames = {"owner_id", "virtual_address"}))
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Contact {

  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "owner_id", nullable = false, updatable = false)
  private User owner;

  @Column(nullable = false, length = 320)
  private String virtualAddress;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  protected Contact() {}

  private Contact(String id, User owner, String virtualAddress) {
    this.id = id;
    this.owner = owner;
    this.virtualAddress = virtualAddress;
  }

  public static Contact of(User owner, String virtualAddress) {
    if (owner == null) {
      throw new IllegalArgumentException("owner is required");
    }
    return new Contact(
        UUID.randomUUID().toString(), owner, VirtualAddress.parse(virtualAddress).toString());
  }
}

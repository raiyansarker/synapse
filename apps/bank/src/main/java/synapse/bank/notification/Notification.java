package synapse.bank.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import synapse.bank.user.User;

@Entity
@Table(name = "notifications")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class Notification {

  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "user_id", nullable = false, updatable = false)
  private User user;

  @Column(nullable = false, length = 120)
  private String title;

  @Column(nullable = false, length = 1024)
  private String message;

  @Column(nullable = false)
  private boolean read;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected Notification() {}

  private Notification(String id, User user, String title, String message) {
    this.id = id;
    this.user = user;
    this.title = title;
    this.message = message;
    this.read = false;
  }

  public static Notification of(User user, String title, String message) {
    if (user == null) {
      throw new IllegalArgumentException("user is required");
    }
    if (title == null || title.isBlank()) {
      throw new IllegalArgumentException("title is required");
    }
    if (message == null || message.isBlank()) {
      throw new IllegalArgumentException("message is required");
    }
    return new Notification(UUID.randomUUID().toString(), user, title, message);
  }

  public void markRead() {
    this.read = true;
  }
}

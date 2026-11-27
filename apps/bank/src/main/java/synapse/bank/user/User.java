package synapse.bank.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener.class)
@Getter
public class User {
  private static final Pattern USERNAME = Pattern.compile("[a-z0-9]+");

  @Id
  @Column(nullable = false, updatable = false, length = 36)
  private String id;

  @Column(nullable = false, unique = true, length = 64)
  private String username;

  @Column(nullable = false, length = 60)
  private String password;

  @Column(nullable = false, length = 32)
  private Role role;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected User() {}

  private User(String id, String username, String password, Role role) {
    this.id = id;
    this.username = username;
    this.password = password;
    this.role = role;
  }

  public static User register(String username, String encodedPassword) {
    return register(username, encodedPassword, Role.CUSTOMER);
  }

  public static User register(String username, String encodedPassword, Role role) {
    if (username == null || !USERNAME.matcher(username).matches()) {
      throw new IllegalArgumentException("username must be [a-z0-9]+, e.g. \"raiyan\"");
    }
    if (encodedPassword == null || encodedPassword.isBlank()) {
      throw new IllegalArgumentException("encoded password is required");
    }
    if (role == null) {
      throw new IllegalArgumentException("role is required");
    }
    return new User(UUID.randomUUID().toString(), username, encodedPassword, role);
  }
}

package synapse.bank.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.util.Arrays;
import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import synapse.bank.account.Account;

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

  @Column(nullable = false, length = 60)
  private String pin;

  @Column(nullable = false, length = 32)
  private Role role;

  @OneToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "account_id", unique = true)
  private Account account;

  @Column(columnDefinition = "bytea")
  private byte[] avatar;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private Instant createdAt;

  @LastModifiedDate
  @Column(nullable = false)
  private Instant updatedAt;

  protected User() {}

  private User(String id, String username, String password, String pin, Role role) {
    this.id = id;
    this.username = username;
    this.password = password;
    this.pin = pin;
    this.role = role;
  }

  public static User register(String username, String encodedPassword, String encodedPin) {
    return register(username, encodedPassword, encodedPin, Role.CUSTOMER);
  }

  public static User register(
      String username,
      String encodedPassword,
      String encodedPin,
      Role role
  ) {
    if (username == null || !USERNAME.matcher(username).matches()) {
      throw new IllegalArgumentException("username must be [a-z0-9]+, e.g. \"raiyan\"");
    }
    if (encodedPassword == null || encodedPassword.isBlank()) {
      throw new IllegalArgumentException("encoded password is required");
    }
    if (encodedPin == null || encodedPin.isBlank()) {
      throw new IllegalArgumentException("encoded pin is required");
    }
    if (role == null) {
      throw new IllegalArgumentException("role is required");
    }
    return new User(UUID.randomUUID().toString(), username, encodedPassword, encodedPin, role);
  }

  public void assignAccount(Account account) {
    if (account == null) {
      throw new IllegalArgumentException("account is required");
    }
    if (!this.username.equals(account.getVirtualAddress())) {
      throw new IllegalArgumentException("account virtual address must match the username");
    }
    this.account = account;
  }

  public void updateAvatar(byte[] avatar) {
    if (avatar == null || avatar.length == 0) {
      throw new IllegalArgumentException("avatar is required");
    }
    this.avatar = Arrays.copyOf(avatar, avatar.length);
  }
}

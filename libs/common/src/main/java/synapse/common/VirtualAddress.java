package synapse.common;

import java.io.Serial;
import java.io.Serializable;
import java.util.Objects;

/**
 * A virtual address, {@code username@bank}. {@link #getUsername()} is the account on that bank.
 * {@link #getBankIdentifier()} is the bank handle the ledger resolves.
 */
public final class VirtualAddress implements Serializable {

  @Serial private static final long serialVersionUID = 1L;

  private final String username;
  private final String bankIdentifier;

  public VirtualAddress(String username, String bankIdentifier) {
    if (!side(username) || !side(bankIdentifier)) {
      throw new IllegalArgumentException("virtual address must look like name@bank");
    }
    this.username = username;
    this.bankIdentifier = bankIdentifier;
  }

  /**
   * Parses {@code username@bank}. Each side is trimmed, then both sides must be non-blank, and the
   * original text must already be that trimmed form. Padding is rejected.
   */
  public static VirtualAddress parse(String value) {
    int at = value == null ? -1 : value.indexOf('@');
    if (value == null || at < 0 || at != value.lastIndexOf('@')) {
      throw new IllegalArgumentException("virtual address must look like name@bank");
    }
    String username = value.substring(0, at).trim();
    String bankIdentifier = value.substring(at + 1).trim();
    if (username.isEmpty()
        || bankIdentifier.isEmpty()
        || !value.equals(username + "@" + bankIdentifier)) {
      throw new IllegalArgumentException("virtual address must look like name@bank");
    }
    return new VirtualAddress(username, bankIdentifier);
  }

  public static boolean matches(String value) {
    try {
      parse(value);
      return true;
    } catch (IllegalArgumentException ex) {
      return false;
    }
  }

  public String getUsername() {
    return username;
  }

  public String getBankIdentifier() {
    return bankIdentifier;
  }

  @Override
  public String toString() {
    return username + "@" + bankIdentifier;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    if (!(other instanceof VirtualAddress address)) {
      return false;
    }
    return username.equals(address.username) && bankIdentifier.equals(address.bankIdentifier);
  }

  @Override
  public int hashCode() {
    return Objects.hash(username, bankIdentifier);
  }

  private static boolean side(String value) {
    return value != null && !value.isBlank() && value.equals(value.trim());
  }
}

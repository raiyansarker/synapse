package synapse.common;

import java.io.Serial;
import java.io.Serializable;
import java.util.Locale;

/**
 * A virtual address, {@code username@bank}. {@code username} is the account on that bank and must
 * be lowercase. {@code bankIdentifier} is the bank handle the ledger resolves.
 */
public record VirtualAddress(String username, String bankIdentifier) implements Serializable {

  @Serial private static final long serialVersionUID = 2L;

  public VirtualAddress {
    if (!side(username) || !side(bankIdentifier) || !lowercase(username)) {
      throw new IllegalArgumentException("virtual address must look like name@bank");
    }
  }

  /**
   * Parses {@code username@bank}. Each side is trimmed, then both sides must be non-blank, and the
   * original text must already be that trimmed form. Padding is rejected. The username must already
   * be lowercase.
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

  @Override
  public String toString() {
    return username + "@" + bankIdentifier;
  }

  private static boolean side(String value) {
    return value != null && !value.isBlank() && value.equals(value.trim());
  }

  private static boolean lowercase(String value) {
    return value.equals(value.toLowerCase(Locale.ROOT));
  }
}

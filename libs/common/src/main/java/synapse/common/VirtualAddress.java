package synapse.common;

import java.io.Serial;
import java.io.Serializable;
import java.util.regex.Pattern;

/**
 * A virtual address, {@code username@bank}. {@code username} is {@code [a-z0-9]+}. {@code
 * bankIdentifier} is {@code [a-z]+} (no digits, dots, or other punctuation).
 */
public record VirtualAddress(String username, String bankIdentifier) implements Serializable {

  @Serial private static final long serialVersionUID = 3L;

  private static final Pattern USERNAME = Pattern.compile("[a-z0-9]+");
  private static final Pattern BANK = Pattern.compile("[a-z]+");

  public VirtualAddress {
    if (!username(username) || !bank(bankIdentifier)) {
      throw new IllegalArgumentException("virtual address must look like name@bank");
    }
  }

  /**
   * Parses {@code username@bank}. One {@code @}, no padding, username {@code [a-z0-9]+}, bank
   * {@code [a-z]+}.
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

  private static boolean username(String value) {
    return value != null && USERNAME.matcher(value).matches();
  }

  private static boolean bank(String value) {
    return value != null && BANK.matcher(value).matches();
  }
}

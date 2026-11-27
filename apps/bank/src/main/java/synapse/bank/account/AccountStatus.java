package synapse.bank.account;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

public enum AccountStatus {
  ACTIVE(false),
  FROZEN(false),
  CLOSED(true);

  private final boolean terminal;

  AccountStatus(boolean terminal) {
    this.terminal = terminal;
  }

  public boolean terminal() {
    return terminal;
  }

  @Converter(autoApply = true)
  static class AsString implements AttributeConverter<AccountStatus, String> {
    @Override
    public String convertToDatabaseColumn(AccountStatus status) {
      return status == null ? null : status.name();
    }

    @Override
    public AccountStatus convertToEntityAttribute(String value) {
      return value == null ? null : AccountStatus.valueOf(value);
    }
  }
}

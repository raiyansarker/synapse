package synapse.bank.ledger;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

public enum EntryType {
  DEBIT,
  CREDIT;

  @Converter(autoApply = true)
  static class AsString implements AttributeConverter<EntryType, String> {
    @Override
    public String convertToDatabaseColumn(EntryType type) {
      return type == null ? null : type.name();
    }

    @Override
    public EntryType convertToEntityAttribute(String value) {
      return value == null ? null : EntryType.valueOf(value);
    }
  }
}

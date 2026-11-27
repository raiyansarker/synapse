package synapse.bank.user;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

public enum Role {
  STAFF,
  CUSTOMER;

  @Converter(autoApply = true)
  static class AsString implements AttributeConverter<Role, String> {
    @Override
    public String convertToDatabaseColumn(Role role) {
      return role == null ? null : role.name();
    }

    @Override
    public Role convertToEntityAttribute(String value) {
      return value == null ? null : Role.valueOf(value);
    }
  }
}

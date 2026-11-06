// =============================================================================
// USER STATE MODEL
// =============================================================================
class UserState {
  final String name;
  final String email;
  final String? avatarPath;
  final bool isBiometricEnabled;

  const UserState({
    required this.name,
    required this.email,
    this.avatarPath,
    this.isBiometricEnabled = false,
  });

  UserState copyWith({
    String? name,
    String? email,
    String? avatarPath,
    bool? isBiometricEnabled,
  }) =>
      UserState(
        name: name ?? this.name,
        email: email ?? this.email,
        avatarPath: avatarPath ?? this.avatarPath,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      );
}

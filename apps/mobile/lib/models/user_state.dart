import '../core/constants/app_colors.dart';

// =============================================================================
// USER STATE MODEL
// =============================================================================
class UserState {
  final String name;
  final String email;
  final String phone;
  /// Payment handle in the form `username@bank` (e.g. `raiyan@ucb`).
  final String virtualAddress;
  final String? avatarPath;

  const UserState({
    required this.name,
    required this.email,
    this.phone = '',
    this.virtualAddress = kDefaultVirtualAddress,
    this.avatarPath,
  });

  UserState copyWith({
    String? name,
    String? email,
    String? phone,
    String? virtualAddress,
    Object? avatarPath = _sentinel,
  }) =>
      UserState(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        virtualAddress: virtualAddress ?? this.virtualAddress,
        avatarPath: avatarPath == _sentinel ? this.avatarPath : avatarPath as String?,
      );

  static const Object _sentinel = Object();
}

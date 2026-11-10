import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../../models/user_state.dart';
import 'app_state.dart';

Future<void> persistUserProfile(UserState u) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('user_name', u.name);
  await p.setString('user_email', u.email);
  await p.setString('user_phone', u.phone);
  await p.setString('user_virtual_address', u.virtualAddress);
  if (u.avatarPath != null) {
    await p.setString('user_avatar', u.avatarPath!);
  } else {
    await p.remove('user_avatar');
  }
}

Future<void> loadStoredUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('user_name');
  final email = prefs.getString('user_email');
  final phone = prefs.getString('user_phone') ?? '';
  final address = prefs.getString('user_virtual_address') ?? kDefaultVirtualAddress;
  final avatar = prefs.getString('user_avatar');

  final base = userNotifier.value;
  userNotifier.value = base.copyWith(
    name: (name != null && name.isNotEmpty) ? name : base.name,
    email: email ?? base.email,
    phone: phone,
    virtualAddress: address,
    avatarPath: avatar,
  );
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'core/state/app_state.dart';
import 'features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  userNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    final u = userNotifier.value;
    await p.setString('user_name', u.name);
    await p.setString('user_email', u.email);
    await p.setBool('biometric_enabled', u.isBiometricEnabled);
    if (u.avatarPath != null) await p.setString('user_avatar', u.avatarPath!);
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: Platform.isIOS ? null : 'Inter',
        scaffoldBackgroundColor: kBgGrey,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kDominantColor,
          primary: kDominantColor,
          surface: kWhite,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/user_state.dart';
import '../../services/transaction_service.dart';
import '../../shell/app_shell.dart';
import 'login_page.dart';

// =============================================================================
// AUTH WRAPPER
// =============================================================================
// Set to false to re-enable the login flow when testing is finished.
const bool _bypassLoginForTesting = true;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkQuickLogin();
  }

  Future<void> _checkQuickLogin() async {
    if (_bypassLoginForTesting) {
      authNotifier.value = true;
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkLoanAutoDeduction();
          checkSavingsAutoCut();
        });
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');
      final isBioEnabled = prefs.getBool('biometric_enabled') ?? false;
      final avatar = prefs.getString('user_avatar');

      if (email != null) {
        userNotifier.value = UserState(
          name: (name != null && name.isNotEmpty && name != 'User') ? name : kHardcodedName,
          email: email,
          isBiometricEnabled: isBioEnabled,
          avatarPath: avatar,
        );
        if (isBioEnabled) {
          final success = await localAuth.authenticate(
            localizedReason: 'Quick Login',
            options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
          );
          if (success) authNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkLoanAutoDeduction();
        checkSavingsAutoCut();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bypassLoginForTesting) {
      return const AppShell();
    }
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kBlack)));
    }
    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (context, _, _) => authNotifier.value ? const AppShell() : const LoginPage(),
    );
  }
}

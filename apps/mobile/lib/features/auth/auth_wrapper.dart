import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/state/user_profile_persistence.dart';
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await loadStoredUserProfile();

    if (_bypassLoginForTesting) {
      authNotifier.value = true;
    } else {
      final email = userNotifier.value.email;
      if (email.isNotEmpty) authNotifier.value = true;
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

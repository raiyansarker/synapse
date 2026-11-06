import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_colors.dart';
import '../state/app_state.dart';

// =============================================================================
// AUTH HELPERS
// =============================================================================
Future<bool> authenticateBiometrics(BuildContext context) async {
  try {
    final withBio = await localAuth.canCheckBiometrics;
    final supported = withBio || await localAuth.isDeviceSupported();
    if (!supported) return true;

    return await localAuth.authenticate(
      localizedReason: 'Authenticate to proceed',
      options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  } catch (_) {
    return false;
  }
}

Future<bool> showPasswordDialog(BuildContext context) async {
  final passCtrl = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Security Check'),
      content: RepaintBoundary(
        child: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password (try: password)',
            hintStyle: TextStyle(color: kTextGrey),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (passCtrl.text == mockUserPassword) {
              Navigator.pop(ctx, true);
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Incorrect password')));
            }
          },
          child: const Text('Unlock'),
        ),
      ],
    ),
  );
  passCtrl.dispose();
  return result ?? false;
}

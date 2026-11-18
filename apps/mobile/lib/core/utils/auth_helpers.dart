import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../state/app_state.dart';

// =============================================================================
// AUTH HELPERS
// =============================================================================
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

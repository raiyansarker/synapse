import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/user_state.dart';

// =============================================================================
// MODAL HELPER: SHOW MY QR MODAL
// =============================================================================
Future<void> showMyQrModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _MyQrSheet(),
  );
}

// =============================================================================
// RECEIVE PAGE (Fallback full-page with identical sleek design)
// =============================================================================
class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My QR Code',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: MyQrContent(),
        ),
      ),
    );
  }
}

// =============================================================================
// MODAL BOTTOM SHEET CONTAINER
// =============================================================================
class _MyQrSheet extends StatelessWidget {
  const _MyQrSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const MyQrContent(),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SLEEK MINIMALIST QR CONTENT
// =============================================================================
class MyQrContent extends StatelessWidget {
  const MyQrContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserState>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        final displayName = user.name.isEmpty ? kHardcodedName : user.name;
        final virtualAddress = user.virtualAddress;
        final qrPayload = 'synapse://pay?to=${Uri.encodeComponent(virtualAddress)}';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Profile Header
            CircleAvatar(
              key: ValueKey(user.avatarPath),
              radius: 28,
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage: userAvatarProvider(user.avatarPath),
            ),
            const SizedBox(height: 10),
            Text(
              virtualAddress,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Scan to pay with Synapse',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 24),

            StyledPaymentQr(data: qrPayload),

            const SizedBox(height: 24),

            // Share QR Code Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Pay $virtualAddress on Synapse: $qrPayload',
                      subject: 'Synapse Payment QR',
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text(
                  'Share QR',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: kWhite,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

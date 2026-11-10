import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_brand_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../features/qr/qr_scanner_page.dart';
import '../../features/send/send_page.dart';
import '../../core/utils/virtual_address.dart';
import '../../features/send/send_recipients.dart';
import '../../core/utils/avatar_image.dart';
import '../../models/user_state.dart';

/// Style theme for the floating bottom navigation bar.
enum NavBarTheme {
  /// Uses the warm sunset coral / terracotta gradient from the top of the home page
  /// for the pill container background.
  homeGradient,

  /// Uses the sleek dark charcoal capsule background from the reference screenshot,
  /// with the home page gradient applied to the center Scan QR button.
  darkCharcoal,
}

class SynapseNavBar extends StatefulWidget {
  final int index;
  final bool showAlert;
  final NavBarTheme theme;

  const SynapseNavBar({
    super.key,
    required this.index,
    required this.showAlert,
    this.theme = NavBarTheme.homeGradient,
  });

  @override
  State<SynapseNavBar> createState() => _SynapseNavBarState();
}

class _SynapseNavBarState extends State<SynapseNavBar> {
  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (!mounted || code == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SendPage(initialCode: code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding : 16.0;

    final isGradient = widget.theme == NavBarTheme.homeGradient;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            gradient: isGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kDominantGradientStart, // 0xFFE26842
                      kDominantGradientMid,   // 0xFFC74C2B
                      kDominantGradientEnd,   // 0xFFA52C16
                    ],
                  )
                : null,
            color: isGradient ? null : const Color(0xFF23252A),
            border: Border.all(
              color: Colors.white.withValues(alpha: isGradient ? 0.20 : 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isGradient
                    ? const Color(0xFFA52C16).withValues(alpha: 0.38)
                    : Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 0: Home
              _buildTabItem(
                slot: 0,
                asset: 'assets/icons/home.svg',
                filledAsset: 'assets/icons/home-solid.svg',
                label: 'Home',
                onTap: () => shellTabIndex.value = 0,
              ),

              // 1: Transactions
              _buildTabItem(
                slot: 1,
                asset: 'assets/icons/receipt.svg',
                filledAsset: 'assets/icons/receipt-solid.svg',
                label: 'Transactions',
                onTap: () => shellTabIndex.value = 1,
              ),

              // 2: Middle Scan QR Button
              _buildCenterScanButton(isGradient: isGradient),

              // 3: Notifications
              _buildTabItem(
                slot: 3,
                asset: 'assets/icons/bell.svg',
                filledAsset: 'assets/icons/bell-solid.svg',
                label: 'Notifications',
                onTap: () => shellTabIndex.value = 3,
                dot: widget.showAlert,
              ),

              // 4: Settings / Profile
              _buildTabItem(
                slot: 4,
                asset: 'assets/icons/user.svg',
                filledAsset: 'assets/icons/user-solid.svg',
                label: 'Settings',
                onTap: () => shellTabIndex.value = 4,
                avatar: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterScanButton({required bool isGradient}) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openScanner,
          child: Semantics(
            button: true,
            label: 'Scan QR',
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isGradient
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [brand.gradientStart, brand.gradientMid],
                      ),
                color: isGradient ? const Color(0xFF1B1D22) : null,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isGradient ? 0.22 : 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isGradient
                        ? Colors.black.withValues(alpha: 0.35)
                        : const Color(0xFFE26842).withValues(alpha: 0.50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CustomPaint(
                  size: Size(22, 22),
                  painter: _ScanReticlePainter(color: Colors.white, strokeWidth: 2.1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int slot,
    required String asset,
    required String filledAsset,
    required String label,
    required VoidCallback onTap,
    bool dot = false,
    bool avatar = false,
  }) {
    final active = slot == widget.index;
    final color = active ? Colors.white : Colors.white.withValues(alpha: 0.55);

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (avatar)
                    _ProfileAvatar(active: active)
                  else
                    SvgPicture.asset(
                      active ? filledAsset : asset,
                      width: 21,
                      height: 21,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  if (dot)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: kRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool active;

  const _ProfileAvatar({required this.active});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserState>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        final image = user.avatarPath != null && File(user.avatarPath!).existsSync()
            ? FileImage(File(user.avatarPath!))
            : const NetworkImage(kDefaultAvatar) as ImageProvider;
        return Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: CircleAvatar(
            key: ValueKey(user.avatarPath),
            radius: 9.5,
            backgroundImage: userAvatarProvider(user.avatarPath),
          ),
        );
      },
    );
  }
}

/// Custom painter for the QR scan reticle matching the exact icon in the reference screenshot:
/// Four rounded corner brackets with a horizontal center line.
class _ScanReticlePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _ScanReticlePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    const corner = 5.5; // length of corner arms
    const r = 2.5;      // corner radius

    // Top-left corner
    final tlPath = Path()
      ..moveTo(0, corner)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(2.5, 0), radius: const Radius.circular(2.5))
      ..lineTo(corner, 0);
    canvas.drawPath(tlPath, paint);

    // Top-right corner
    final trPath = Path()
      ..moveTo(w - corner, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(2.5))
      ..lineTo(w, corner);
    canvas.drawPath(trPath, paint);

    // Bottom-left corner
    final blPath = Path()
      ..moveTo(0, h - corner)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: const Radius.circular(2.5))
      ..lineTo(corner, h);
    canvas.drawPath(blPath, paint);

    // Bottom-right corner
    final brPath = Path()
      ..moveTo(w - corner, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: const Radius.circular(2.5))
      ..lineTo(w, h - corner);
    canvas.drawPath(brPath, paint);

    // Center horizontal dash / scan line
    const dashHalfWidth = 4.8;
    canvas.drawLine(
      Offset(w / 2 - dashHalfWidth, h / 2),
      Offset(w / 2 + dashHalfWidth, h / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanReticlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

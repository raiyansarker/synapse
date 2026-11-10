import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// =============================================================================
// CIRCULAR ACTION BUTTON WIDGET (Inspired by reference UI)
// =============================================================================
class ActionButton extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    this.icon,
    this.asset,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (asset != null) {
      iconWidget = SvgPicture.asset(
        asset!,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    } else if (icon != null) {
      iconWidget = Icon(icon, color: iconColor, size: 22);
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Green stroke check on a white disc; [progress] 0 → 1 draws the mark.
class AnimatedCheckMark extends StatelessWidget {
  final double progress;
  final double size;
  final Color checkColor;

  const AnimatedCheckMark({
    super.key,
    required this.progress,
    this.size = 108,
    this.checkColor = kGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CheckMarkPainter(progress: progress, color: checkColor),
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckMarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 1, ring);

    final checkProgress = Curves.easeOut.transform(
      ((progress - 0.12) / 0.88).clamp(0.0, 1.0),
    );
    if (checkProgress <= 0) return;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final start = Offset(size.width * 0.28, size.height * 0.52);
    final mid = Offset(size.width * 0.43, size.height * 0.67);
    final end = Offset(size.width * 0.74, size.height * 0.36);

    final firstLen = (mid - start).distance;
    final secondLen = (end - mid).distance;
    final total = firstLen + secondLen;
    final drawn = total * checkProgress;

    if (drawn <= firstLen) {
      canvas.drawLine(start, Offset.lerp(start, mid, drawn / firstLen)!, stroke);
    } else {
      canvas.drawLine(start, mid, stroke);
      canvas.drawLine(mid, Offset.lerp(mid, end, (drawn - firstLen) / secondLen)!, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) => oldDelegate.progress != progress;
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

// Minimal shared pieces for send / confirm / processing / success.

class FlowAmountHero extends StatelessWidget {
  final String digits;
  final double symbolSize;
  final double amountSize;

  const FlowAmountHero({
    super.key,
    required this.digits,
    this.symbolSize = 36,
    this.amountSize = 56,
  });

  factory FlowAmountHero.money(double amount) {
    final digits = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return FlowAmountHero(digits: digits, symbolSize: 32, amountSize: 48);
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: amountSize * 0.18),
            child: Text(
              '৳',
              style: TextStyle(
                fontSize: symbolSize,
                fontWeight: FontWeight.w600,
                color: kBlack,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            digits,
            style: TextStyle(
              fontSize: amountSize,
              fontWeight: FontWeight.w700,
              color: kBlack,
              letterSpacing: -1.5,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class FlowMoneyLine extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const FlowMoneyLine({super.key, required this.amount, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(amount),
      style: style ??
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: kBlack,
            letterSpacing: -0.8,
          ),
    );
  }
}

class FlowRecipientRow extends StatelessWidget {
  final String name;
  final String virtualAddress;
  final String? avatarUrl;
  final double avatarRadius;

  const FlowRecipientRow({
    super.key,
    required this.name,
    required this.virtualAddress,
    this.avatarUrl,
    this.avatarRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          backgroundColor: kBgGrey,
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: avatarRadius * 0.55,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTransferInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                virtualAddress,
                style: const TextStyle(fontSize: 13, color: kTextGrey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FlowRecipientHero extends StatelessWidget {
  final String name;
  final String virtualAddress;
  final String? avatarUrl;

  const FlowRecipientHero({
    super.key,
    required this.name,
    required this.virtualAddress,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          backgroundColor: kBgGrey,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTransferInk),
        ),
        const SizedBox(height: 4),
        Text(
          virtualAddress,
          style: const TextStyle(fontSize: 14, color: kTextGrey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class FlowReceiptBlock extends StatelessWidget {
  final List<FlowReceiptRow> rows;

  const FlowReceiptBlock({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ],
      ],
    );
  }
}

class FlowReceiptRow extends StatelessWidget {
  static const _labelWidth = 92.0;

  final String label;
  final String value;
  final Color? valueColor;

  const FlowReceiptRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: kTextGrey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kTransferInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FlowPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FlowPrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: kBlack, foregroundColor: kWhite),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Full-width amount stage (#E2E2E0).
class FlowAmountStage extends StatelessWidget {
  final Widget child;

  const FlowAmountStage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: kTransferTopTone, child: child);
  }
}

class FlowKeypadDock extends StatelessWidget {
  final Widget child;

  const FlowKeypadDock({super.key, required this.child});

  static const _topSquircle = BorderRadius.vertical(top: Radius.circular(32));

  static const keypadInsets = EdgeInsets.fromLTRB(20, 16, 20, 8);

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: _topSquircle,
      child: ColoredBox(
        color: kWhite,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: keypadInsets,
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../send/widgets/transfer_flow_ui.dart';
import 'widgets/animated_check_mark.dart';
import 'widgets/transfer_status_layout.dart';

class SuccessPage extends StatefulWidget {
  final double? amount;
  final String? recipientName;
  final String? virtualAddress;
  final String? avatarUrl;
  final bool isRequest;

  const SuccessPage({
    super.key,
    this.amount,
    this.recipientName,
    this.virtualAddress,
    this.avatarUrl,
    this.isRequest = false,
  });

  bool get isTransfer => amount != null && recipientName != null;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late final AnimationController _check;

  @override
  void initState() {
    super.initState();
    _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _check.forward().then((_) {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTransfer) {
      return _genericSuccess(context);
    }

    final now = DateTime.now();
    final ref = 'REF${now.millisecondsSinceEpoch.toString().substring(5)}';
    final time =
        '${now.day}/${now.month}/${now.year} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final isRequest = widget.isRequest;

    return AnimatedBuilder(
      animation: _check,
      builder: (context, child) {
        return TransferStatusLayout(
          statusVisual: AnimatedCheckMark(
            progress: Curves.easeOutCubic.transform(_check.value),
            size: 88,
          ),
          headline: isRequest ? 'Request sent' : 'Transfer sent',
          subheadline: formatMoney(widget.amount!),
          recipientName: widget.recipientName!,
          virtualAddress: widget.virtualAddress ?? '',
          avatarUrl: widget.avatarUrl,
          detailRows: isRequest
              ? [
                  const FlowReceiptRow(label: 'Status', value: 'Pending', valueColor: kTransferInk),
                  FlowReceiptRow(label: 'Amount', value: formatMoney(widget.amount!)),
                  FlowReceiptRow(label: 'Reference', value: ref),
                  FlowReceiptRow(label: 'Time', value: time),
                ]
              : [
                  const FlowReceiptRow(label: 'Status', value: 'Completed', valueColor: kGreen),
                  FlowReceiptRow(label: 'Amount', value: formatMoney(widget.amount!)),
                  FlowReceiptRow(label: 'Reference', value: ref),
                  FlowReceiptRow(label: 'Time', value: time),
                ],
          bottom: FlowPrimaryButton(
            label: 'Back to Home',
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        );
      },
    );
  }

  Widget _genericSuccess(BuildContext context) {
    return TransferStatusLayout(
      statusVisual: AnimatedCheckMark(progress: 1, size: 88),
      headline: 'All set',
      subheadline: 'Your transaction is complete',
      recipientName: 'Synapse',
      virtualAddress: '—',
      detailRows: const [
        FlowReceiptRow(label: 'Status', value: 'Completed', valueColor: kGreen),
      ],
      bottom: FlowPrimaryButton(
        label: 'Back to Home',
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../send/widgets/transfer_flow_ui.dart';
import 'success_page.dart';
import 'widgets/transfer_status_layout.dart';

class TransferProcessingPage extends StatefulWidget {
  final double amount;
  final String recipientName;
  final String virtualAddress;
  final String? avatarUrl;

  const TransferProcessingPage({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.virtualAddress,
    this.avatarUrl,
  });

  @override
  State<TransferProcessingPage> createState() => _TransferProcessingPageState();
}

class _TransferProcessingPageState extends State<TransferProcessingPage> with SingleTickerProviderStateMixin {
  static const _delay = Duration(milliseconds: 2400);

  late final AnimationController _progress;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _delay)..forward();
    _navTimer = Timer(_delay, _finish);
  }

  void _finish() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessPage(
          amount: widget.amount,
          recipientName: widget.recipientName,
          virtualAddress: widget.virtualAddress,
          avatarUrl: widget.avatarUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return TransferStatusLayout(
            statusVisual: SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: _progress.value,
                strokeWidth: 3,
                color: kBlack,
                backgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
            headline: 'Sending money',
            subheadline: 'Your transfer is being processed',
            recipientName: widget.recipientName,
            virtualAddress: widget.virtualAddress,
            avatarUrl: widget.avatarUrl,
            detailRows: [
              const FlowReceiptRow(label: 'Status', value: 'Processing', valueColor: kTransferInk),
              FlowReceiptRow(label: 'Amount', value: formatMoney(widget.amount)),
            ],
          );
        },
      ),
    );
  }
}

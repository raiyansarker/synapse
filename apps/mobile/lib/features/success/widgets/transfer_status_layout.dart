import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../send/widgets/transfer_flow_ui.dart';

/// Shared layout for pending (processing) and sent (success) transfer screens.
class TransferStatusLayout extends StatelessWidget {
  final Widget statusVisual;
  final String headline;
  final String? subheadline;
  final String recipientName;
  final String virtualAddress;
  final String? avatarUrl;
  final List<FlowReceiptRow> detailRows;
  final Widget? bottom;

  const TransferStatusLayout({
    super.key,
    required this.statusVisual,
    required this.headline,
    this.subheadline,
    required this.recipientName,
    required this.virtualAddress,
    this.avatarUrl,
    required this.detailRows,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(child: statusVisual),
              const SizedBox(height: 20),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTransferInk,
                  letterSpacing: -0.3,
                ),
              ),
              if (subheadline != null) ...[
                const SizedBox(height: 6),
                Text(
                  subheadline!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: kTextGrey, height: 1.35),
                ),
              ],
              const SizedBox(height: 28),
              _TransferSummaryCard(
                recipientName: recipientName,
                virtualAddress: virtualAddress,
                avatarUrl: avatarUrl,
                rows: detailRows,
              ),
              const Spacer(),
              if (bottom != null) ...[
                bottom!,
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferSummaryCard extends StatelessWidget {
  final String recipientName;
  final String virtualAddress;
  final String? avatarUrl;
  final List<FlowReceiptRow> rows;

  const _TransferSummaryCard({
    required this.recipientName,
    required this.virtualAddress,
    this.avatarUrl,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: kBgGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowRecipientRow(
            name: recipientName,
            virtualAddress: virtualAddress,
            avatarUrl: avatarUrl,
            avatarRadius: 22,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          FlowReceiptBlock(rows: rows),
        ],
      ),
    );
  }
}

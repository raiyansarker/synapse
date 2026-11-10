import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

// =============================================================================
// CLEAN & MINIMAL TRANSACTION DETAILS MODAL
// =============================================================================
void showTransactionDetailsModal(BuildContext context, Tx tx) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 200),
      reverseDuration: Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
    ),
    builder: (context) => _TransactionDetailsSheet(tx: tx),
  );
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Tx tx;

  const _TransactionDetailsSheet({required this.tx});

  String _formatTxId(String id) {
    if (id.length >= 8) {
      return 'SYN-${id.substring(id.length - 8).toUpperCase()}';
    }
    return 'SYN-00$id';
  }

  @override
  Widget build(BuildContext context) {
    final amountText = '${tx.isIncome ? '+' : '−'}${formatMoney(tx.amount.abs())}';
    final txId = _formatTxId(tx.id);

    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimal drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Clean Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tx.isIncome ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.displayIcon,
                  size: 24,
                  color: tx.isIncome ? kGreen : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                tx.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: kTextGrey,
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: tx.isIncome ? kGreen : kBlack,
                ),
              ),
              const SizedBox(height: 24),

              // Clean Divider
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 8),

              // Key-value Details
              _DetailItem(label: 'Status', value: 'Completed', isSuccess: true),
              _DetailItem(label: 'Date & Time', value: tx.time),
              _DetailItem(
                label: 'Transaction ID',
                value: txId,
                valueColor: const Color(0xFF1D4ED8),
                onValueTap: () {
                  Clipboard.setData(ClipboardData(text: txId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 1),
                      content: Text('Transaction ID copied'),
                    ),
                  );
                },
              ),
              const _DetailItem(label: 'Payment Method', value: 'Synapse Wallet'),
              const _DetailItem(label: 'Fee', value: 'Free (৳0.00)'),

              const SizedBox(height: 24),

              // Clean Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isSuccess;
  final Color? valueColor;
  final VoidCallback? onValueTap;

  const _DetailItem({
    required this.label,
    required this.value,
    this.isSuccess = false,
    this.valueColor,
    this.onValueTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? (isSuccess ? kGreen : kBlack);
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
    );

    Widget valueWidget = Text(value, style: valueStyle);
    if (onValueTap != null) {
      valueWidget = GestureDetector(
        onTap: onValueTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Text(value, style: valueStyle),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: kTextGrey),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? kGreen : kBlack,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onCopy,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 14, color: kTextGrey),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

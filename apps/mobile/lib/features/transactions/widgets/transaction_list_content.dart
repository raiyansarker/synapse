import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';
import '../transaction_visual.dart';
import 'transaction_details_modal.dart';

/// Grouped transaction list used on the Transactions tab.
class TransactionListContent extends StatelessWidget {
  final List<Tx> txs;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry padding;

  /// When true, height follows content and defers scrolling to a parent [ScrollView].
  final bool shrinkWrap;

  const TransactionListContent({
    super.key,
    required this.txs,
    this.scrollController,
    this.padding = const EdgeInsets.only(top: 4),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) return const TransactionListEmpty();

    final today = <Tx>[];
    final yesterday = <Tx>[];
    final earlier = <Tx>[];
    for (final tx in txs) {
      final when = tx.time;
      if (when.startsWith('Today') || when == 'Just now') {
        today.add(tx);
      } else if (when.startsWith('Yesterday')) {
        yesterday.add(tx);
      } else {
        earlier.add(tx);
      }
    }

    return ListView(
      controller: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        if (today.isNotEmpty) ...[
          const TransactionSectionLabel('Today'),
          ..._buildGroupedTiles(today),
        ],
        if (yesterday.isNotEmpty) ...[
          const TransactionSectionLabel('Yesterday'),
          ..._buildGroupedTiles(yesterday),
        ],
        if (earlier.isNotEmpty) ...[
          const TransactionSectionLabel('Earlier'),
          ..._buildGroupedTiles(earlier),
        ],
      ],
    );
  }

  List<Widget> _buildGroupedTiles(List<Tx> items) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      widgets.add(TransactionListTile(items[i]));
      if (i < items.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 20,
            color: Color(0xFFF8FAFC),
          ),
        );
      }
    }
    return widgets;
  }
}

class TransactionListTile extends StatelessWidget {
  final Tx tx;

  const TransactionListTile(this.tx, {super.key});

  @override
  Widget build(BuildContext context) {
    final amount = '${tx.isIncome ? '+' : '−'}${formatMoney(tx.amount.abs())}';
    final (bgColor, iconColor) = transactionIconColors(tx);

    return InkWell(
      onTap: () => showTransactionDetailsModal(context, tx),
      splashColor: const Color(0xFFF1F5F9),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(tx.displayIcon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tx.subtitle} • ${tx.time}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: tx.isIncome ? const Color(0xFF059669) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionSectionLabel extends StatelessWidget {
  final String title;

  const TransactionSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class TransactionListEmpty extends StatelessWidget {
  const TransactionListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
              child: Center(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: Icon(Icons.receipt_long_outlined, size: 52, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

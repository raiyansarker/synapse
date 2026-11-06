import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import 'widgets/transaction_details_modal.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<Tx>>(
        valueListenable: transactionsNotifier,
        builder: (context, txs, _) {
          if (txs.isEmpty) return const _EmptyTransactions();

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
            padding: EdgeInsets.only(top: 4, bottom: bottomInset),
            children: [
              if (today.isNotEmpty) ...[
                const _SectionLabel('Today'),
                ..._buildGroupedTiles(today),
              ],
              if (yesterday.isNotEmpty) ...[
                const _SectionLabel('Yesterday'),
                ..._buildGroupedTiles(yesterday),
              ],
              if (earlier.isNotEmpty) ...[
                const _SectionLabel('Earlier'),
                ..._buildGroupedTiles(earlier),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedTiles(List<Tx> items) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_TxTile(items[i]));
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

class _TxTile extends StatelessWidget {
  final Tx tx;

  const _TxTile(this.tx);

  (Color bg, Color fg) _getColors() {
    if (tx.isIncome) {
      return (const Color(0xFFECFDF5), const Color(0xFF059669));
    }
    final sub = tx.subtitle.toLowerCase();
    final title = tx.title.toLowerCase();
    if (sub.contains('food') || title.contains('cafe')) {
      return (const Color(0xFFFFF7ED), const Color(0xFFEA580C));
    }
    if (sub.contains('bill') || sub.contains('subscription') || title.contains('electricity') || title.contains('netflix')) {
      return (const Color(0xFFEFF6FF), const Color(0xFF2563EB));
    }
    if (sub.contains('ride') || title.contains('pathao') || title.contains('uber')) {
      return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
    if (sub.contains('grocery') || title.contains('store')) {
      return (const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
    }
    return (const Color(0xFFF8FAFC), const Color(0xFF334155));
  }

  @override
  Widget build(BuildContext context) {
    final amount = '${tx.isIncome ? '+' : '−'}${formatMoney(tx.amount.abs())}';
    final (bgColor, iconColor) = _getColors();

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

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

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

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

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

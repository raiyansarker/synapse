import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../models/transaction.dart';
import '../../transactions/widgets/transaction_list_content.dart';

/// Full-width squircle sheet: no scroll; shows only rows that fit on screen.
class HomeActivityPanel extends StatelessWidget {
  const HomeActivityPanel({super.key});

  static const BorderRadius _sheetTopSquircle = BorderRadius.vertical(
    top: Radius.circular(36),
  );

  static const double _sectionLabelHeight = 34;
  static const double _rowHeight = 69;

  static int _maxVisibleItems(double listHeight) {
    if (listHeight <= _sectionLabelHeight) return 0;
    final forRows = listHeight - _sectionLabelHeight;
    return (forRows / _rowHeight).floor().clamp(0, 24);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: _sheetTopSquircle,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 4),
              child: Row(
                children: [
                  const Text(
                    'Recent transactions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => shellTabIndex.value = 1,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View all'),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxItems = _maxVisibleItems(constraints.maxHeight);
                  return ValueListenableBuilder<List<Tx>>(
                    valueListenable: transactionsNotifier,
                    builder: (context, txs, _) {
                      if (txs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      }

                      final preview = txs.take(maxItems).toList();
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: TransactionListContent(
                            txs: preview,
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

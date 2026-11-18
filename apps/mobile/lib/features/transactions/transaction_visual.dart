import 'package:flutter/material.dart';

import '../../models/transaction.dart';

(Color bg, Color fg) transactionIconColors(Tx tx) {
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

String transactionShortTime(String time) {
  final comma = time.indexOf(',');
  if (comma != -1) return time.substring(comma + 1).trim();
  return time;
}

bool transactionIsToday(Tx tx) =>
    tx.time.startsWith('Today') || tx.time == 'Just now';

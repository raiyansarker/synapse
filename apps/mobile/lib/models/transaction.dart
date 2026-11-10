import 'package:flutter/material.dart';

// =============================================================================
// TRANSACTION MODEL
// =============================================================================
class Tx {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String time;
  final IconData icon;
  final bool isIncome;

  const Tx({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.icon,
    this.isIncome = false,
  });

  IconData get displayIcon {
    if (icon == Icons.north_east ||
        icon == Icons.north_east_rounded ||
        icon == Icons.arrow_upward ||
        icon == Icons.arrow_upward_rounded ||
        icon == Icons.file_upload_outlined) {
      return Icons.file_upload_outlined;
    }
    if (icon == Icons.south_west ||
        icon == Icons.south_west_rounded ||
        icon == Icons.arrow_downward ||
        icon == Icons.arrow_downward_rounded ||
        icon == Icons.file_download_outlined) {
      return Icons.file_download_outlined;
    }
    return icon;
  }
}

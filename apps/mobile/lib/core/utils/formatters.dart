// =============================================================================
// FORMATTERS
// =============================================================================
String formatMoney(double v) {
  final abs = v.abs().toStringAsFixed(2);
  final parts = abs.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '৳${v < 0 ? '-' : ''}${buf.toString()}.${parts[1]}';
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

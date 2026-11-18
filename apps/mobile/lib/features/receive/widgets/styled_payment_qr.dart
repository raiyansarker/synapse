import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Styled QR without a surrounding container.
class StyledPaymentQr extends StatelessWidget {
  final String data;

  const StyledPaymentQr({super.key, required this.data});

  static const _ink = Color(0xFF0F172A);

  static const _decoration = PrettyQrDecoration(
    shape: PrettyQrDotsSymbol(color: _ink),
    background: Colors.transparent,
    quietZone: PrettyQrQuietZone.modules(2),
  );

  static const double _qrSize = 208;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _qrSize,
        height: _qrSize,
        child: PrettyQrView.data(
          data: data,
          errorCorrectLevel: QrErrorCorrectLevel.M,
          decoration: _decoration,
        ),
      ),
    );
  }
}

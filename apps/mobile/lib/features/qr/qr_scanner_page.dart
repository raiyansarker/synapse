import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';

// =============================================================================
// QR SCANNER PAGE
// =============================================================================
class QrScannerPage extends StatefulWidget {
  final bool popOnDetect;
  final ValueChanged<String>? onCode;

  const QrScannerPage({super.key, this.popOnDetect = true, this.onCode});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  DateTime? _lastHit;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_lastHit != null && DateTime.now().difference(_lastHit!) < const Duration(seconds: 2)) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw == null) continue;
                var code = raw;
                if (raw.startsWith('wallet://pay') || raw.contains('code=')) {
                  try {
                    code = Uri.parse(raw).queryParameters['code'] ?? raw;
                  } catch (_) {}
                }
                _lastHit = DateTime.now();
                if (widget.popOnDetect) {
                  Navigator.pop(context, code);
                } else {
                  widget.onCode?.call(code);
                }
                return;
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: kWhite, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: const Center(child: Text('Align QR within the frame', style: TextStyle(color: kWhite, fontSize: 16))),
          ),
          Positioned(
            top: 0,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: kWhite,
                  fixedSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

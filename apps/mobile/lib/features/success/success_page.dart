import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// =============================================================================
// SUCCESS PAGE
// =============================================================================
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: kBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 50, color: kWhite),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaction Successful',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const _DetailRow(
                      label: 'Status',
                      value: 'Completed',
                      valueColor: kGreen,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Reference',
                      value:
                          'REF${now.millisecondsSinceEpoch.toString().substring(7)}',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Date',
                      value: '${now.day}/${now.month}/${now.year}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? kBlack,
          ),
        ),
      ],
    );
  }
}

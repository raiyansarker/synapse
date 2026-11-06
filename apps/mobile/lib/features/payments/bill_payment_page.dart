import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../success/success_page.dart';

// =============================================================================
// BILL PAYMENT PAGE
// =============================================================================
class BillPaymentPage extends StatefulWidget {
  final String billerName;
  final String idLabel;

  const BillPaymentPage({
    super.key,
    required this.billerName,
    required this.idLabel,
  });

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _idController = TextEditingController();
  bool _isLoading = false;
  double? _dueAmount;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _checkBill() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.idLabel}')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _dueAmount = (id.hashCode % 500) + 45.50;
    });
  }

  Future<void> _processPayment() async {
    if (_dueAmount! > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kRed,
          content: Text(
            'Insufficient balance. Please take a loan or receive money.',
          ),
        ),
      );
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await authenticateBiometrics(context);
      if (!authorized && mounted) authorized = await showPasswordDialog(context);
    } else {
      authorized = await showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    addTransaction(
      Tx(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.billerName,
        subtitle: 'Bill Payment',
        amount: -_dueAmount!,
        time: 'Just now',
        icon: Icons.receipt_long,
        isIncome: false,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlack),
          onPressed: () {
            if (_dueAmount != null) {
              setState(() => _dueAmount = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.billerName,
          style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _dueAmount == null ? _buildInputScreen() : _buildBillScreen(),
        ),
      ),
    );
  }

  Widget _buildInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.receipt_long, size: 60, color: kBlack),
        const SizedBox(height: 24),
        Text(
          'Pay ${widget.billerName} Bill',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your ${widget.idLabel} to fetch the current due amount.',
          style: const TextStyle(color: kTextGrey),
        ),
        const SizedBox(height: 40),
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.numbers, color: kTextGrey),
                ),
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, color: kBlack),
                    decoration: InputDecoration(
                      hintText: widget.idLabel,
                      hintStyle: const TextStyle(color: kTextGrey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkBill,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: kWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Check Bill',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kBlack,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, color: kWhite, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Total Due',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '৳${_dueAmount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailRow('Biller', widget.billerName),
              const Divider(height: 24),
              _buildDetailRow(widget.idLabel, _idController.text),
              const Divider(height: 24),
              _buildDetailRow('Status', 'Unpaid', valueColor: Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pay ৳${_dueAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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

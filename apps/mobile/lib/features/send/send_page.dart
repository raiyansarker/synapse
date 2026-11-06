import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../features/qr/qr_scanner_page.dart';
import '../../features/success/success_page.dart';

// =============================================================================
// SEND PAGE
// =============================================================================
class SendPage extends StatefulWidget {
  final String? initialCode;
  final bool isRequest;
  const SendPage({super.key, this.initialCode, this.isRequest = false});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  late final TextEditingController _codeController;
  String _amount = '0';

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    FocusScope.of(context).unfocus();

    setState(() {
      if (key == 'back') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
          _amount += key;
        }
      }
    });
  }

  Future<void> _processTransfer() async {
    final code = _codeController.text.trim();
    final amt = double.tryParse(_amount) ?? 0;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a recipient code')));
      return;
    }

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (widget.isRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment request of ৳$amt sent to $code'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (amt > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please receive money first.'),
      ));
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

    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.isRequest ? 'Requested from $code' : 'Sent to $code',
      subtitle: widget.isRequest ? 'Request' : 'Transfer',
      amount: widget.isRequest ? amt : -amt,
      time: 'Just now',
      icon: widget.isRequest ? Icons.file_download_outlined : Icons.file_upload_outlined,
      isIncome: widget.isRequest,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: Text(widget.isRequest ? 'Request Money' : 'Send Money', style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: kBlack),
            onPressed: () async {
              final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerPage()));
              if (result != null) {
                _codeController.text = result;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(color: kBgGrey, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20, right: 12),
                      child: Icon(Icons.person_outline, color: kBlack),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        style: const TextStyle(fontSize: 16, color: kBlack, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: widget.isRequest ? 'Enter payer code' : 'Enter recipient code',
                          hintStyle: const TextStyle(color: kTextGrey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text('৳$_amount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: kBlack)),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: balanceNotifier,
            builder: (context, balance, _) => Text('Available: ${formatMoney(balance)}', style: const TextStyle(color: kTextGrey)),
          ),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                _buildKeyRow(['4', '5', '6']),
                _buildKeyRow(['7', '8', '9']),
                _buildKeyRow(['.', '0', 'back']),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlack,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isRequest ? Icons.arrow_downward : Icons.lock, size: 18),
                    const SizedBox(width: 8),
                    Text(widget.isRequest ? 'Request Money' : 'Confirm Transfer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        return InkWell(
          onTap: () => _onKeyPress(k),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            child: k == 'back'
                ? const Icon(Icons.backspace_outlined, color: kBlack)
                : Text(k, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: kBlack)),
          ),
        );
      }).toList(),
    );
  }
}

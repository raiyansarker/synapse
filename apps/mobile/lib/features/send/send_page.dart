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

    if (!await showSendConfirmSheet(context, recipient: widget.recipient, amount: amt)) return;
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Sent to ${widget.recipient.name}',
      subtitle: 'Transfer',
      amount: -amt,
      time: 'Just now',
      icon: Icons.file_upload_outlined,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TransferProcessingPage(
          amount: amt,
          recipientName: widget.recipient.name,
          virtualAddress: widget.recipient.virtualAddress,
          avatarUrl: widget.recipient.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRequest ? 'Request Money' : 'Send Money';

    return Scaffold(
      backgroundColor: kTransferTopTone,
      appBar: AppBar(
        backgroundColor: kTransferTopTone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: kBlack, fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FlowAmountStage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Column(
                  children: [
                    FlowRecipientHero(
                      name: widget.recipient.name,
                      virtualAddress: widget.recipient.virtualAddress,
                      avatarUrl: widget.recipient.avatarUrl,
                    ),
                    const Spacer(),
                    FlowAmountHero(digits: _amount),
                    const SizedBox(height: 8),
                    if (!widget.isRequest)
                      ValueListenableBuilder<double>(
                        valueListenable: balanceNotifier,
                        builder: (context, balance, child) => Text(
                          'Available ${formatMoney(balance)}',
                          style: const TextStyle(color: kTextGrey, fontSize: 15),
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          FlowKeypadDock(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: _quickAmounts.map((v) {
                    final on = _amount == v.toString();
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: v == _quickAmounts.last ? 0 : 8),
                        child: _QuickPill(
                          label: '$v',
                          selected: on,
                          onTap: () => _setPresetAmount(v),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                AmountKeypad(onKey: _onKeyPress),
                const SizedBox(height: 10),
                FlowPrimaryButton(
                  label: widget.isRequest ? 'Request Money' : 'Confirm Transfer',
                  onPressed: _processTransfer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kBlack : kBgGrey,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? kWhite : kBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../success/success_page.dart';
import '../success/transfer_processing_page.dart';
import 'send_recipients.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/send_confirm_sheet.dart';
import 'widgets/transfer_flow_ui.dart';

class SendPage extends StatefulWidget {
  final SendRecipient recipient;
  final bool isRequest;

  const SendPage({super.key, required this.recipient, this.isRequest = false});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  static const _quickAmounts = [50, 100, 500, 1000];
  String _amount = '0';

  void _setPresetAmount(int value) {
    HapticFeedback.selectionClick();
    setState(() => _amount = value.toString());
  }

  void _onKeyPress(String key) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (key == 'back') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else if (_amount == '0') {
        _amount = key;
      } else if (!_amount.contains('.') || _amount.split('.')[1].length < 2) {
        _amount += key;
      }
    });
  }

  Future<void> _processTransfer() async {
    final amt = double.tryParse(_amount) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (widget.isRequest) {
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            amount: amt,
            recipientName: widget.recipient.name,
            virtualAddress: widget.recipient.virtualAddress,
            avatarUrl: widget.recipient.avatarUrl,
            isRequest: true,
          ),
        ),
      );
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

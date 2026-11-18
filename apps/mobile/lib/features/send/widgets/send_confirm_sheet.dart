import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/formatters.dart';
import '../send_recipients.dart';
import 'transfer_flow_ui.dart';

Future<bool> showSendConfirmSheet(
  BuildContext context, {
  required SendRecipient recipient,
  required double amount,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SendConfirmSheet(recipient: recipient, amount: amount),
  );
  return result ?? false;
}

class _SendConfirmSheet extends StatefulWidget {
  final SendRecipient recipient;
  final double amount;

  const _SendConfirmSheet({required this.recipient, required this.amount});

  @override
  State<_SendConfirmSheet> createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<_SendConfirmSheet> {
  final _pinCtrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  static const _pinLength = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pinCtrl.text.trim().length < _pinLength) {
      setState(() => _error = 'Enter all $_pinLength digits');
      HapticFeedback.lightImpact();
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final after = balanceNotifier.value - widget.amount;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height - viewInsets.bottom - 16;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm with PIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTransferInk),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FlowRecipientRow(
                              name: widget.recipient.name,
                              virtualAddress: widget.recipient.virtualAddress,
                              avatarUrl: widget.recipient.avatarUrl,
                              avatarRadius: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FlowMoneyLine(
                            amount: widget.amount,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Balance after ${formatMoney(after)}',
                          style: const TextStyle(fontSize: 13, color: kTextGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _PinDots(
                  controller: _pinCtrl,
                  focusNode: _focus,
                  length: _pinLength,
                  hasError: _error != null,
                  onChanged: () => setState(() => _error = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kRed, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                FlowPrimaryButton(label: 'Pay ${formatMoney(widget.amount)}', onPressed: _submit),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Cancel', style: TextStyle(color: kTextGrey, fontWeight: FontWeight.w600)),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final VoidCallback onChanged;

  const _PinDots({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pin = controller.text;
        final active = pin.length < length ? pin.length : length - 1;

        return GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(length, (i) {
                  final filled = i < pin.length;
                  final isActive = i == active && pin.length < length;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? kBlack : Colors.transparent,
                        border: Border.all(
                          color: hasError ? kRed : (filled ? kBlack : const Color(0xFFD1D5DB)),
                          width: isActive ? 2 : 1.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: 20,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                  decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  showCursor: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

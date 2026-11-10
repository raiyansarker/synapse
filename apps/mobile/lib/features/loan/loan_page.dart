import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';

// =============================================================================
// LOAN PAGE
// =============================================================================
class LoanPage extends StatefulWidget {
  const LoanPage({super.key});
  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _takeLoan() async {
    final amt = double.tryParse(_amountController.text) ?? 0;
    final maxLimit = isProNotifier.value ? 5000.0 : 1000.0;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (amt > maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: kRed,
        content: Text('Amount exceeds your limit of ${formatMoney(maxLimit)}'),
      ));
      return;
    }
    if (loanNotifier.value > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('You must clear your previous loan first.'),
      ));
      return;
    }

    final authorized = await showPasswordDialog(context);

    if (!authorized) return;
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    loanNotifier.value = amt;
    loanDueDateNotifier.value = DateTime.now().add(const Duration(days: 30));

    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Loan Disbursed',
      subtitle: 'Advance',
      amount: amt,
      time: 'Just now',
      icon: Icons.payments,
      isIncome: true,
    ));

    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kGreen,
      content: Text('Loan of ${formatMoney(amt)} disbursed successfully!'),
    ));
  }

  Future<void> _repayLoan() async {
    final amt = loanNotifier.value;
    if (amt <= 0) return;

    final authorized = await showPasswordDialog(context);

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Loan Repayment',
      subtitle: 'Cleared',
      amount: -amt,
      time: 'Just now',
      icon: Icons.check_circle,
      isIncome: false,
    ));

    loanNotifier.value = 0;
    loanDueDateNotifier.value = null;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: kGreen,
      content: Text('Loan fully repaid!'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Loan / Advance', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.payments, size: 60, color: kBlack),
              const SizedBox(height: 24),
              const Text('Take a Loan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text('Get instant funds. Repay within 30 days.', style: TextStyle(color: kTextGrey)),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kBlack)),
                    ValueListenableBuilder<bool>(
                      valueListenable: isProNotifier,
                      builder: (context, isPro, _) => Text(
                        isPro ? '৳5,000' : '৳1,000',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGreen),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ValueListenableBuilder<double>(
                valueListenable: loanNotifier,
                builder: (context, activeLoan, _) {
                  if (activeLoan > 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding Loan', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(formatMoney(activeLoan), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kBlack)),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<DateTime?>(
                                valueListenable: loanDueDateNotifier,
                                builder: (context, dueDate, _) => Text(
                                  'Due Date: ${dueDate != null ? formatDate(dueDate) : "N/A"}',
                                  style: const TextStyle(color: kTextGrey, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('You must repay your current loan before taking a new one.', style: TextStyle(color: kTextGrey, fontSize: 12)),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _repayLoan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlack,
                              foregroundColor: kWhite,
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                                : const Text('Repay Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Enter Amount (৳)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, right: 12),
                                  child: Text('৳', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: kTextGrey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your loan will be due in 30 days. If unpaid, the amount will be automatically deducted, potentially resulting in a negative balance.',
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _takeLoan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlack,
                              foregroundColor: kWhite,
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                                : const Text('Take Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

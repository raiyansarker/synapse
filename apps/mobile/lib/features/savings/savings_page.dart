import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';

// =============================================================================
// SAVINGS PAGE
// =============================================================================
class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});
  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _isLoading = false;

  Future<void> _withdraw() async {
    final startDate = savingsStartDateNotifier.value;
    if (startDate == null) return;

    if (DateTime.now().difference(startDate).inDays < 365) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('You can only withdraw after 1 year.'),
      ));
      return;
    }

    if (savingsBalanceNotifier.value <= 0) return;

    final authorized = await showPasswordDialog(context);

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final amt = savingsBalanceNotifier.value;
    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Savings Withdrawn',
      subtitle: 'To Main Balance',
      amount: amt,
      time: 'Just now',
      icon: Icons.savings,
      isIncome: true,
    ));

    savingsBalanceNotifier.value = 0;
    savingsEnabledNotifier.value = false;
    savingsStartDateNotifier.value = null;
    lastSavingsCutNotifier.value = null;
    missedSavingsNotifier.value = false;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kGreen,
      content: Text('Successfully withdrawn ${formatMoney(amt)}!'),
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
        title: const Text('Savings', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                  child: const Icon(Icons.savings, color: kWhite, size: 60),
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: Text('Total Savings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack))),
              const SizedBox(height: 8),
              Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: savingsBalanceNotifier,
                  builder: (context, balance, _) => Text(
                    formatMoney(balance),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kGreen),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: savingsEnabledNotifier,
                      builder: (context, enabled, _) => SwitchListTile(
                        secondary: const Icon(Icons.autorenew, color: kBlack),
                        title: const Text('Auto-Save 100 TK/month', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Automatically cuts 100 TK every 30 days.'),
                        value: enabled,
                        activeThumbColor: kBlack,
                        onChanged: (val) {
                          if (!val) {
                            final startDate = savingsStartDateNotifier.value;
                            if (startDate != null && DateTime.now().difference(startDate).inDays < 365) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                backgroundColor: kRed,
                                content: Text('Auto-save is locked for 1 year. You cannot turn it off.'),
                              ));
                              return;
                            }
                          }

                          savingsEnabledNotifier.value = val;
                          if (val) {
                            savingsStartDateNotifier.value = DateTime.now();
                            lastSavingsCutNotifier.value = DateTime.now();
                            missedSavingsNotifier.value = false;
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ValueListenableBuilder<bool>(
                      valueListenable: missedSavingsNotifier,
                      builder: (context, missed, _) {
                        if (!missed) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Warning: You missed a payment! Next cut will be 210 TK (100 double + 10 penalty).',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Warning: Turning on Auto-Save locks your deposited savings for 1 year. You cannot turn it off or withdraw until then.',
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
                  onPressed: _isLoading ? null : _withdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                      : const Text('Withdraw Savings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

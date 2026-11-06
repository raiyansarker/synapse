import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../features/success/success_page.dart';

// =============================================================================
// UPGRADE PAGE (Synapse Pro)
// =============================================================================
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});
  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  bool _isLoading = false;

  Future<void> _processUpgrade() async {
    if (500.0 > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please take a loan or receive money first.'),
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

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    isProNotifier.value = true;
    purchasedSubsNotifier.value = [...purchasedSubsNotifier.value, 'Synapse Pro'];

    addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Synapse Pro Upgrade',
      subtitle: 'Subscription',
      amount: -500.0,
      time: 'Just now',
      icon: Icons.stars,
      isIncome: false,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Synapse Pro', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                child: const Icon(Icons.stars, color: kWhite, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Upgrade to Synapse Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text(
                'Unlock premium features and get more out of your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextGrey, fontSize: 16),
              ),

              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.check_circle, '5% Cashback on all bills'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.check_circle, 'Higher loan limit (up to ৳5,000)'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.check_circle, 'Priority customer support'),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Text('Monthly Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text('৳500.00 / month', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                      : const Text('Subscribe for ৳500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kBlack, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: kBlack, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

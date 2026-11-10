import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../models/subscription.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../success/success_page.dart';

// =============================================================================
// SUBSCRIPTION CHECKOUT PAGE
// =============================================================================
class SubscriptionCheckoutPage extends StatefulWidget {
  final SubModel sub;
  const SubscriptionCheckoutPage({super.key, required this.sub});

  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  final _accountIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountIdController.dispose();
    super.dispose();
  }

  Future<void> _processPurchase() async {
    final accountId = _accountIdController.text.trim();
    if (accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your ${widget.sub.emailLabel}')),
      );
      return;
    }

    if (widget.sub.price > balanceNotifier.value) {
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

    final authorized = await showPasswordDialog(context);

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    purchasedSubsNotifier.value = [
      ...purchasedSubsNotifier.value,
      widget.sub.name,
    ];

    addTransaction(
      Tx(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.sub.name} Subscription',
        subtitle: 'For $accountId',
        amount: -widget.sub.price,
        time: 'Just now',
        icon: widget.sub.icon,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buy ${widget.sub.name}',
          style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold),
        ),
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
                  decoration: BoxDecoration(
                    color: kWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(widget.sub.icon, size: 64, color: kBlack),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the account information needed to activate your ${widget.sub.name} subscription.',
                style: const TextStyle(color: kTextGrey, fontSize: 14),
              ),
              const SizedBox(height: 24),
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
                        child: Icon(Icons.person, color: kTextGrey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _accountIdController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16, color: kBlack),
                          decoration: InputDecoration(
                            hintText: widget.sub.emailLabel,
                            hintStyle: const TextStyle(color: kTextGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subscription Fee',
                          style: TextStyle(color: kTextGrey),
                        ),
                        Text(
                          formatMoney(widget.sub.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBlack,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBlack,
                          ),
                        ),
                        Text(
                          formatMoney(widget.sub.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ${formatMoney(widget.sub.price)}',
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
          ),
        ),
      ),
    );
  }
}

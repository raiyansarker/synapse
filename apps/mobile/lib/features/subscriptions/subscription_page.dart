import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/formatters.dart';
import '../../models/subscription.dart';
import '../upgrade/upgrade_page.dart';
import 'subscription_benefits_page.dart';

// =============================================================================
// SUBSCRIPTION PAGE
// =============================================================================
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

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
        title: const Text(
          'Subscriptions',
          style: TextStyle(color: kBlack, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: availableSubs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final sub = availableSubs[i];

          if (sub.name == 'Synapse Pro') {
            return ValueListenableBuilder<bool>(
              valueListenable: isProNotifier,
              builder: (context, isPro, _) {
                if (isPro) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kBlack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars, color: kWhite, size: 24),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Synapse Pro Active',
                            style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(Icons.check_circle, color: kGreen, size: 24),
                      ],
                    ),
                  );
                }
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradePage()),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBlack.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stars, color: kBlack, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Synapse Pro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kBlack,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Get 5% cashback and higher limits',
                                style: TextStyle(color: kTextGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(sub.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionBenefitsPage(sub: sub),
              ),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBlack.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(sub.icon, color: kBlack, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Monthly subscription',
                          style: TextStyle(color: kTextGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(sub.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kBlack,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

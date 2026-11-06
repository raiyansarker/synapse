import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../features/home/home_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/transactions/transactions_page.dart';
import 'nav_tab_transition_stack.dart';
import 'synapse_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([shellTabIndex, loanNotifier, missedSavingsNotifier]),
      builder: (context, _) {
        final index = shellTabIndex.value.clamp(0, 4).toInt();
        final page = index > 2 ? index - 1 : index;
        final alert = loanNotifier.value > 0 || missedSavingsNotifier.value;
        return Scaffold(
          backgroundColor: kBgGrey,
          body: NavTabTransitionStack(
            index: page.clamp(0, 3),
            children: const [
              HomePage(),
              TransactionsPage(),
              NotificationsPage(),
              ProfilePage(embedded: true),
            ],
          ),
          bottomNavigationBar: SynapseNavBar(index: index == 2 ? 0 : index, showAlert: alert),
        );
      },
    );
  }
}

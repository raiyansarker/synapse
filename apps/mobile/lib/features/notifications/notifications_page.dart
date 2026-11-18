import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/formatters.dart';

// =============================================================================
// MINIMALIST NOTIFICATIONS PAGE (No Back Button, User Photos on Transfers)
// =============================================================================
class NotificationsPage extends StatefulWidget {
  final bool embedded;
  const NotificationsPage({super.key, this.embedded = false});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _readIds = {'read_1', 'read_2', 'read_3', 'read_4'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllAsRead(List<_NotificationItem> allItems) {
    setState(() {
      for (final item in allItems) {
        _readIds.add(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + (widget.embedded ? 100 : 20);

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, // No back button
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: Listenable.merge([
              transactionsNotifier,
              loanNotifier,
              missedSavingsNotifier,
            ]),
            builder: (context, _) {
              final allItems = _buildAllItems();
              return TextButton(
                onPressed: () => _markAllAsRead(allItems),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1D77FF),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D77FF),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                indicatorColor: const Color(0xFF0F172A),
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: const Color(0xFFF1F5F9),
                tabs: const [
                  Tab(text: 'Read'),
                  Tab(text: 'Unread'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          transactionsNotifier,
          loanNotifier,
          loanDueDateNotifier,
          missedSavingsNotifier,
        ]),
        builder: (context, _) {
          final allItems = _buildAllItems();
          final readItems = allItems.where((e) => _readIds.contains(e.id)).toList();
          final unreadItems = allItems.where((e) => !_readIds.contains(e.id)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Read Tab
              _buildList(readItems, isUnreadTab: false, bottomInset: bottomInset),
              // Unread Tab
              _buildList(unreadItems, isUnreadTab: true, bottomInset: bottomInset),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<_NotificationItem> items, {required bool isUnreadTab, required double bottomInset}) {
    if (items.isEmpty) {
      return const _EmptyNotificationView();
    }

    final todayItems = items.where((e) => e.section == _Section.today).toList();
    final yesterdayItems = items.where((e) => e.section == _Section.yesterday).toList();
    final earlierItems = items.where((e) => e.section == _Section.earlier).toList();

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: bottomInset),
      children: [
        if (todayItems.isNotEmpty) ...[
          const _SectionLabel('Today'),
          ...todayItems.map((item) => _buildRow(item, showDot: isUnreadTab)),
        ],
        if (yesterdayItems.isNotEmpty) ...[
          const _SectionLabel('Yesterday'),
          ...yesterdayItems.map((item) => _buildRow(item, showDot: isUnreadTab)),
        ],
        if (earlierItems.isNotEmpty) ...[
          const _SectionLabel('Earlier'),
          ...earlierItems.map((item) => _buildRow(item, showDot: isUnreadTab)),
        ],
      ],
    );
  }

  Widget _buildRow(_NotificationItem item, {required bool showDot}) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_readIds.contains(item.id)) {
            _readIds.remove(item.id);
          } else {
            _readIds.add(item.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: User Photo (for transactions) OR Minimal Icon (for system alerts)
            if (item.avatarUrl != null)
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: NetworkImage(item.avatarUrl!),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Icon(
                  item.icon,
                  size: 19,
                  color: const Color(0xFF334155),
                ),
              ),
            const SizedBox(width: 14),

            // Middle text message
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // Right unread indicator dot
            if (showDot) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D77FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_NotificationItem> _buildAllItems() {
    final list = <_NotificationItem>[];

    // Dynamic Loan Alert
    if (loanNotifier.value > 0) {
      final due = loanDueDateNotifier.value;
      list.add(
        _NotificationItem(
          id: 'loan_alert',
          icon: Icons.credit_card_outlined,
          message: due == null
              ? 'Alerts, Your loan repayment of ${formatMoney(loanNotifier.value)} is currently pending.'
              : 'Alerts, Your loan repayment of ${formatMoney(loanNotifier.value)} will be auto-deducted on ${formatDate(due)}.',
          section: _Section.today,
        ),
      );
    }

    // Dynamic Missed Savings
    if (missedSavingsNotifier.value) {
      list.add(
        const _NotificationItem(
          id: 'savings_alert',
          icon: Icons.warning_amber_rounded,
          message: 'Alerts, Monthly auto-save cut failed. Next deduction will be ৳210.00 with penalty.',
          section: _Section.today,
        ),
      );
    }

    // Unread items (Today)
    list.add(
      const _NotificationItem(
        id: 'unread_1',
        icon: Icons.calendar_today_outlined,
        message: 'Congratulations, Your booking for a relaxing spa session has been confirmed.',
        section: _Section.today,
      ),
    );

    list.add(
      const _NotificationItem(
        id: 'unread_2',
        icon: Icons.schedule_outlined,
        message: 'Your preferred stylist, Lisa, is available for appointment in 25 minutes.',
        section: _Section.today,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
      ),
    );

    // Transaction sent to Raiyan Sarker (with user photo)
    list.add(
      const _NotificationItem(
        id: 'unread_3',
        icon: Icons.account_balance_wallet_outlined,
        message: 'Congratulations, Your payment of ৳1,500.00 has been transferred to Raiyan Sarker.',
        section: _Section.today,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      ),
    );

    // Transaction received from Tahmid Adim (with user photo)
    list.add(
      const _NotificationItem(
        id: 'unread_5',
        icon: Icons.south_west_rounded,
        message: 'Congratulations, You received ৳420.00 from Tahmid Adim successfully.',
        section: _Section.today,
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150&auto=format&fit=crop&q=80',
      ),
    );

    list.add(
      const _NotificationItem(
        id: 'unread_4',
        icon: Icons.lock_outline_rounded,
        message: 'Alerts, Your security password has been changed after 30 minutes wait.',
        section: _Section.today,
      ),
    );

    // Yesterday items
    // Transaction sent to Nusrat Jahan (with user photo)
    list.add(
      const _NotificationItem(
        id: 'read_1',
        icon: Icons.account_balance_wallet_outlined,
        message: 'Congratulations, Your payment of ৳850.00 to Nusrat Jahan has been transferred successfully.',
        section: _Section.yesterday,
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
      ),
    );

    list.add(
      const _NotificationItem(
        id: 'read_2',
        icon: Icons.lock_outline_rounded,
        message: 'Alerts, Your password has been changed after 30 minutes wait.',
        section: _Section.yesterday,
      ),
    );

    // Earlier items
    // Transaction received from Sadia Islam (with user photo)
    list.add(
      const _NotificationItem(
        id: 'read_4',
        icon: Icons.credit_card_outlined,
        message: 'Congratulations, You received payment of ৳2,000.00 from Sadia Islam.',
        section: _Section.earlier,
        avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
      ),
    );

    list.add(
      const _NotificationItem(
        id: 'read_3',
        icon: Icons.calendar_today_outlined,
        message: 'Your preferred stylist, Lisa, is available for appointment in 25 minutes.',
        section: _Section.earlier,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
      ),
    );

    // Dynamic session transactions
    for (final tx in transactionsNotifier.value.take(3)) {
      list.insert(
        0,
        _NotificationItem(
          id: tx.id,
          icon: tx.icon,
          message: tx.isIncome
              ? 'Congratulations, Received payment of ${formatMoney(tx.amount)} successfully.'
              : 'Payment transferred, ${formatMoney(tx.amount.abs())} sent for ${tx.title}.',
          section: _Section.today,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
        ),
      );
    }

    return list;
  }
}

// =============================================================================
// SECTION LABEL
// =============================================================================
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

// =============================================================================
// MINIMALIST EMPTY NOTIFICATION VIEW
// =============================================================================
class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 52,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notification yet!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DATA TYPES
// =============================================================================
enum _Section { today, yesterday, earlier }

class _NotificationItem {
  final String id;
  final IconData icon;
  final String message;
  final _Section section;
  final String? avatarUrl;

  const _NotificationItem({
    required this.id,
    required this.icon,
    required this.message,
    required this.section,
    this.avatarUrl,
  });
}

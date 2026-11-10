import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../features/home/home_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/transactions/transactions_page.dart';
import 'synapse_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  static const _pages = <Widget>[
    HomePage(),
    TransactionsPage(),
    NotificationsPage(),
    ProfilePage(embedded: true),
  ];

  static int _pageFromShellTab(int shellIndex) {
    if (shellIndex <= 1) return shellIndex;
    if (shellIndex == 2) return 0;
    return shellIndex - 1;
  }

  late final AnimationController _transition;
  late final CurvedAnimation _progress;

  int _page = 0;
  int _fromPage = 0;
  int _toPage = 0;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _page = _pageFromShellTab(shellTabIndex.value.clamp(0, 4).toInt());
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _progress = CurvedAnimation(parent: _transition, curve: Curves.easeOutCubic);
    _transition.addListener(() => setState(() {}));
    _transition.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _page = _toPage;
      _transition.value = 0;
      if (mounted) setState(() {});
    });
    shellTabIndex.addListener(_onShellTabChanged);
    loanNotifier.addListener(_onChromeChanged);
    missedSavingsNotifier.addListener(_onChromeChanged);
  }

  @override
  void dispose() {
    shellTabIndex.removeListener(_onShellTabChanged);
    loanNotifier.removeListener(_onChromeChanged);
    missedSavingsNotifier.removeListener(_onChromeChanged);
    _progress.dispose();
    _transition.dispose();
    super.dispose();
  }

  void _onChromeChanged() => setState(() {});

  void _onShellTabChanged() {
    final next = _pageFromShellTab(shellTabIndex.value.clamp(0, 4).toInt());
    if (next == _toPage && _transition.isAnimating) return;
    if (next == _page && !_transition.isAnimating) return;

    if (_transition.isAnimating) {
      _transition.stop();
      _page = _toPage;
    }
    if (next == _page) return;

    _fromPage = _page;
    _toPage = next;
    _direction = next > _fromPage ? 1 : -1;
    _transition.forward(from: 0);
  }

  Widget _tabPage(int index) {
    return KeyedSubtree(
      key: ValueKey<int>(index),
      child: _pages[index],
    );
  }

  Widget _buildTabBody() {
    if (!_transition.isAnimating) {
      return _tabPage(_page);
    }

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-0.22 * _direction, 0),
    ).animate(_progress);
    final slideIn = Tween<Offset>(
      begin: Offset(0.22 * _direction, 0),
      end: Offset.zero,
    ).animate(_progress);
    final fadeOut = Tween<double>(begin: 1, end: 0).animate(_progress);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: fadeOut,
            child: SlideTransition(position: slideOut, child: _tabPage(_fromPage)),
          ),
          FadeTransition(
            opacity: _progress,
            child: SlideTransition(position: slideIn, child: _tabPage(_toPage)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = shellTabIndex.value.clamp(0, 4).toInt();
    final alert = loanNotifier.value > 0 || missedSavingsNotifier.value;

    return Scaffold(
      backgroundColor: kBgGrey,
      body: _buildTabBody(),
      bottomNavigationBar: SynapseNavBar(index: index == 2 ? 0 : index, showAlert: alert),
    );
  }
}

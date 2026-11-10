import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../features/qr/qr_scanner_page.dart';
import '../../features/send/send_page.dart';
import '../../core/utils/virtual_address.dart';
import '../../features/send/send_recipients.dart';
import '../../core/utils/avatar_image.dart';
import '../../models/user_state.dart';

class SynapseNavBar extends StatefulWidget {
  final int index;
  final bool showAlert;

  const SynapseNavBar({super.key, required this.index, required this.showAlert});

  @override
  State<SynapseNavBar> createState() => _SynapseNavBarState();
}

class _SynapseNavBarState extends State<SynapseNavBar> with SingleTickerProviderStateMixin {
  static const _slotCount = 5;

  late final AnimationController _controller;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = AlwaysStoppedAnimation(widget.index.toDouble());
  }

  @override
  void didUpdateWidget(SynapseNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    final next = widget.index.toDouble();
    _slide = Tween<double>(begin: _slide.value, end: next).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (!mounted || code == null) return;
    final target = resolvePaymentTarget(code) ?? code;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendPage(recipient: sendRecipientFromCode(target)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      clipBehavior: Clip.none,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _slotCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Positioned(
                          top: 0,
                          left: _slide.value * slot + (slot - 22) / 2,
                          child: Container(
                            width: 22,
                            height: 2,
                            decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(2)),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        _item(slot: 0, asset: 'assets/icons/home.svg', filled: 'assets/icons/home-solid.svg', label: 'Home', onTap: () => shellTabIndex.value = 0),
                        _item(slot: 1, asset: 'assets/icons/receipt.svg', filled: 'assets/icons/receipt-solid.svg', label: 'Transactions', onTap: () => shellTabIndex.value = 1),
                        _scanItem(),
                        _item(slot: 3, asset: 'assets/icons/bell.svg', filled: 'assets/icons/bell-solid.svg', label: 'Notifications', onTap: () => shellTabIndex.value = 3, dot: widget.showAlert),
                        _item(slot: 4, asset: 'assets/icons/user.svg', filled: 'assets/icons/user-solid.svg', label: 'Settings', onTap: () => shellTabIndex.value = 4, avatar: true),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanItem() {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Scan QR',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openScanner,
          child: SizedBox(
            height: 66,
            child: OverflowBox(
              maxHeight: 96,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: kBlack,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/scan-barcode-solid.svg',
                        width: 29,
                        height: 29,
                        colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item({
    required int slot,
    required String asset,
    required String filled,
    required String label,
    required VoidCallback onTap,
    bool dot = false,
    bool avatar = false,
  }) {
    final active = slot == widget.index;
    final color = active ? kBlack : kTextGrey;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (avatar)
                  _ProfileAvatar(active: active)
                else
                  _NavIcon(asset: active ? filled : asset, color: color),
                if (dot)
                  const Positioned(
                    right: -2,
                    top: -1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: kRed, shape: BoxShape.circle),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool active;

  const _ProfileAvatar({required this.active});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserState>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        return Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? kBlack : Colors.transparent, width: 1.5),
          ),
          child: CircleAvatar(
            key: ValueKey(user.avatarPath),
            radius: 11,
            backgroundImage: userAvatarProvider(user.avatarPath),
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String asset;
  final Color color;

  const _NavIcon({required this.asset, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

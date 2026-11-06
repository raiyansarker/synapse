import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/user_state.dart';
import '../../models/transaction.dart';
import '../../core/utils/formatters.dart';
import '../../features/send/send_page.dart';
import '../../features/receive/receive_page.dart';
import '../transactions/widgets/transaction_details_modal.dart';
import 'widgets/action_button.dart';

// =============================================================================
// HOME PAGE
// =============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  late final AnimationController _gradientController;
  late final Animation<double> _gradientAnimation;
  late double _screenHeight;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.of(context).size.height;
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  ImageProvider _avatarProvider(UserState u) =>
      u.avatarPath != null && File(u.avatarPath!).existsSync()
          ? FileImage(File(u.avatarPath!))
          : const NetworkImage(kDefaultAvatar) as ImageProvider;

  static const double _kSheetInitialSize = 0.58;
  static const double _kSheetMinSize = 0.50;

  @override
  Widget build(BuildContext context) {
    final isDominantDark = ThemeData.estimateBrightnessForColor(kDominantColor) == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDominantDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kDominantGradientDark,
        body: AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, _) {
            final t = _gradientAnimation.value;
            final color1 = Color.lerp(const Color(0xFFE26842), const Color(0xFFEA5A35), t)!;
            final color2 = Color.lerp(const Color(0xFFC74C2B), const Color(0xFFB83D1F), t)!;
            final color3 = Color.lerp(const Color(0xFFA52C16), const Color(0xFF8B220F), t)!;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.6 + 0.8 * t, -1.0),
                  end: Alignment(0.6 - 0.8 * t, 1.0),
                  colors: [color1, color2, color3],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Restructured Compact Top Section
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
                            child: ValueListenableBuilder<UserState>(
                              valueListenable: userNotifier,
                              builder: (context, user, _) => Row(
                                children: [
                                  CircleAvatar(radius: 18, backgroundImage: _avatarProvider(user)),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Hello,',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                                      ),
                                      Text(
                                        user.name.isEmpty ? kHardcodedName : user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => shellTabIndex.value = 4,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.settings_outlined, size: 20, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Push amount down
                          const SizedBox(height: 24),

                          // Balance Display (with amount pushed after currency icon)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: ValueListenableBuilder<double>(
                                valueListenable: balanceNotifier,
                                builder: (context, balance, _) {
                                  final formatted = formatMoney(balance); // e.g. "৳84,250.80"
                                  String symbol = '';
                                  String numberStr = formatted;
                                  if (formatted.isNotEmpty && !RegExp(r'[0-9\-]').hasMatch(formatted[0])) {
                                    symbol = formatted[0];
                                    numberStr = formatted.substring(1);
                                  }
                                  final dotIndex = numberStr.lastIndexOf('.');
                                  final mainPart = dotIndex != -1 ? numberStr.substring(0, dotIndex) : numberStr;
                                  final decimalPart = dotIndex != -1 ? numberStr.substring(dotIndex) : '';

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      if (symbol.isNotEmpty) ...[
                                        Text(
                                          symbol,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.70),
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8), // Pushes amount after the currency icon
                                      ],
                                      Text(
                                        mainPart,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 38,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      if (decimalPart.isNotEmpty)
                                        Text(
                                          decimalPart,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.50),
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.0,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                          // Space between amount and buttons
                          const SizedBox(height: 24),

                          // Action Buttons (Send, Request, My Code)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ActionButton(
                                  icon: Icons.file_upload_outlined,
                                  label: 'Send',
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPage())),
                                ),
                                ActionButton(
                                  icon: Icons.file_download_outlined,
                                  label: 'Request',
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPage(isRequest: true))),
                                ),
                                ActionButton(
                                  icon: Icons.qr_code_2_rounded,
                                  label: 'My QR',
                                  onTap: () => showMyQrModal(context),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),

                // Swipeable Bottom Sheet
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: _kSheetInitialSize,
                  minChildSize: _kSheetMinSize,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) {
                              final delta = details.primaryDelta ?? 0.0;
                              final newSize = _sheetController.size - (delta / _screenHeight);
                              _sheetController.jumpTo(newSize.clamp(_kSheetMinSize, 1.0));
                            },
                            onVerticalDragEnd: (details) {
                              if (_sheetController.size > 0.82) {
                                _sheetController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              } else {
                                _sheetController.animateTo(_kSheetInitialSize, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                                ),
                              ),
                            ),
                          ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Text('Latest Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ValueListenableBuilder<List<Tx>>(
                          valueListenable: transactionsNotifier,
                          builder: (context, txs, _) {
                            if (txs.isEmpty) {
                              return const Center(
                                child: Text('No recent transactions', style: TextStyle(color: kTextGrey)),
                              );
                            }
                            return ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              itemCount: txs.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final tx = txs[i];
                                return InkWell(
                                  onTap: () => showTransactionDetailsModal(context, tx),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(color: kBgGrey, shape: BoxShape.circle),
                                          child: Icon(tx.displayIcon, color: kBlack, size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBlack)),
                                              const SizedBox(height: 4),
                                              Text(tx.time, style: const TextStyle(color: kTextGrey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${tx.isIncome ? '+' : ''}${formatMoney(tx.amount)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tx.isIncome ? kGreen : kBlack),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  },
),
),
);
}


}

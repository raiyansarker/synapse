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
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, appBrandVariantNotifier]),
      builder: (context, _) {
        final brand = brandPaletteFor(appBrandVariantNotifier.value);
        final isDominantDark = ThemeData.estimateBrightnessForColor(brand.gradientEnd) == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDominantDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: brand.gradientDark,
            body: AnimatedBuilder(
              animation: _gradientAnimation,
              builder: (context, _) {
                final t = _gradientAnimation.value;
                final color1 = Color.lerp(brand.animColor1A, brand.animColor1B, t)!;
                final color2 = Color.lerp(brand.animColor2A, brand.animColor2B, t)!;
                final color3 = Color.lerp(brand.animColor3A, brand.animColor3B, t)!;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
                      child: ValueListenableBuilder<UserState>(
                        valueListenable: userNotifier,
                        builder: (context, user, _) => Row(
                          children: [
                            GestureDetector(
                              onTap: () => shellTabIndex.value = 4,
                              child: CircleAvatar(
                                key: ValueKey(user.avatarPath),
                                radius: 18,
                                backgroundImage: userAvatarProvider(user.avatarPath),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Hello,',
                                  style: TextStyle(fontSize: 11, color: brand.heroMutedColor),
                                ),
                                Text(
                                  user.name.isEmpty ? kHardcodedName : user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: brand.heroTitleColor,
                                  ),
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
                                  color: brand.heroActionCircleColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.settings_outlined, size: 20, color: brand.heroIconColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: ValueListenableBuilder<double>(
                          valueListenable: balanceNotifier,
                          builder: (context, balance, _) {
                            final formatted = formatMoney(balance);
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
                                      color: brand.heroMutedColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  mainPart,
                                  style: TextStyle(
                                    color: brand.heroTitleColor,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                if (decimalPart.isNotEmpty)
                                  Text(
                                    decimalPart,
                                    style: TextStyle(
                                      color: brand.heroMutedColor,
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
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ActionButton(
                            icon: Icons.file_upload_outlined,
                            label: 'Send',
                            iconColor: brand.heroIconColor,
                            labelColor: brand.heroTitleColor,
                            circleColor: brand.heroActionCircleColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SendRecipientPickerPage()),
                            ),
                          ),
                          ActionButton(
                            icon: Icons.file_download_outlined,
                            label: 'Request',
                            iconColor: brand.heroIconColor,
                            labelColor: brand.heroTitleColor,
                            circleColor: brand.heroActionCircleColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SendRecipientPickerPage(isRequest: true)),
                            ),
                          ),
                          ActionButton(
                            icon: Icons.qr_code_2_rounded,
                            label: 'My QR',
                            iconColor: brand.heroIconColor,
                            labelColor: brand.heroTitleColor,
                            circleColor: brand.heroActionCircleColor,
                            onTap: () => showMyQrModal(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Expanded(child: HomeActivityPanel()),
                  ],
                ),
              ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'core/constants/app_brand_theme.dart';
import 'core/constants/app_button_styles.dart';
import 'core/constants/app_colors.dart';
import 'core/state/app_state.dart';
import 'core/state/user_profile_persistence.dart';
import 'features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  userNotifier.addListener(() => persistUserProfile(userNotifier.value));
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppBrandVariant>(
      valueListenable: appBrandVariantNotifier,
      builder: (context, variant, _) {
        final brand = brandPaletteFor(variant);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: applyAppButtonThemes(
            ThemeData(
              useMaterial3: true,
              fontFamily: Platform.isIOS ? null : 'Inter',
              scaffoldBackgroundColor: kBgGrey,
              colorScheme: ColorScheme.fromSeed(
                seedColor: brand.accent,
                primary: brand.accent,
                surface: kWhite,
              ),
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

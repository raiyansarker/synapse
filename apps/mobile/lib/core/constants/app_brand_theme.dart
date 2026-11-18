import 'package:flutter/material.dart';

/// Home hero + chrome accent: warm coral (default) or purple.
enum AppBrandVariant { coral, purple }

@immutable
class AppBrandPalette {
  final Color accent;
  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;
  final Color animColor1A;
  final Color animColor1B;
  final Color animColor2A;
  final Color animColor2B;
  final Color animColor3A;
  final Color animColor3B;
  final Color navBarShadow;
  /// Home transaction sheet (warm / tinted, not flat gray).
  final Color activitySheet;

  const AppBrandPalette({
    required this.accent,
    required this.gradientStart,
    required this.gradientMid,
    required this.gradientEnd,
    required this.animColor1A,
    required this.animColor1B,
    required this.animColor2A,
    required this.animColor2B,
    required this.animColor3A,
    required this.animColor3B,
    required this.navBarShadow,
    required this.activitySheet,
  });

  Color get gradientDark => gradientEnd;

  List<Color> get navBarGradientColors => [gradientStart, gradientMid, gradientEnd];

  bool get heroUsesLightForeground =>
      ThemeData.estimateBrightnessForColor(gradientMid) == Brightness.light;

  Color get heroTitleColor =>
      heroUsesLightForeground ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

  Color get heroMutedColor => heroUsesLightForeground
      ? const Color(0xFF64748B)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.75);

  Color get heroIconColor =>
      heroUsesLightForeground ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

  Color get heroActionCircleColor => heroUsesLightForeground
      ? const Color(0xFF0F172A).withValues(alpha: 0.08)
      : const Color(0xFF000000).withValues(alpha: 0.20);
}

const AppBrandPalette kCoralBrandPalette = AppBrandPalette(
  accent: Color(0xFFEAEAE8),
  gradientStart: Color(0xFFF3F2F0),
  gradientMid: Color(0xFFEAEAE8),
  gradientEnd: Color(0xFFD8D6D2),
  animColor1A: Color(0xFFF0EFED),
  animColor1B: Color(0xFFEAEAE8),
  animColor2A: Color(0xFFE5E4E1),
  animColor2B: Color(0xFFDFDDDA),
  animColor3A: Color(0xFFD8D6D2),
  animColor3B: Color(0xFFD0CEC9),
  navBarShadow: Color(0xFFB5B3B0),
  activitySheet: Color(0xFFFFFFFF),
);

const AppBrandPalette kPurpleBrandPalette = AppBrandPalette(
  accent: Color(0xFF6D28D9),
  gradientStart: Color(0xFF7C3AED),
  gradientMid: Color(0xFF5B21B6),
  gradientEnd: Color(0xFF3B0764),
  animColor1A: Color(0xFF8B5CF6),
  animColor1B: Color(0xFF7C3AED),
  animColor2A: Color(0xFF6D28D9),
  animColor2B: Color(0xFF5B21B6),
  animColor3A: Color(0xFF5B21B6),
  animColor3B: Color(0xFF4C1D95),
  navBarShadow: Color(0xFF3B0764),
  activitySheet: Color(0xFFFFFFFF),
);

AppBrandPalette brandPaletteFor(AppBrandVariant variant) {
  switch (variant) {
    case AppBrandVariant.coral:
      return kCoralBrandPalette;
    case AppBrandVariant.purple:
      return kPurpleBrandPalette;
  }
}

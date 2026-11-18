import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Pill-shaped controls used for all Material buttons in the app.
const StadiumBorder kAppButtonShape = StadiumBorder();

const RoundedRectangleBorder kAppTappableShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20)),
);

ButtonStyle appPrimaryElevatedStyle({
  Color backgroundColor = kBlack,
  Color foregroundColor = kWhite,
}) {
  return ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    shape: kAppButtonShape,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

ButtonStyle appTextButtonStyle({Color? foregroundColor}) {
  return TextButton.styleFrom(
    foregroundColor: foregroundColor,
    shape: kAppButtonShape,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
}

ButtonStyle appOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    shape: kAppButtonShape,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  );
}

ButtonStyle appFilledButtonStyle() {
  return FilledButton.styleFrom(
    elevation: 0,
    shape: kAppButtonShape,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  );
}

ThemeData applyAppButtonThemes(ThemeData base) {
  return base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(style: appPrimaryElevatedStyle()),
    filledButtonTheme: FilledButtonThemeData(style: appFilledButtonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: appOutlinedButtonStyle()),
    textButtonTheme: TextButtonThemeData(style: appTextButtonStyle()),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: kAppButtonShape),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(kAppButtonShape),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      ),
    ),
  );
}

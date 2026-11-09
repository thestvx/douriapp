import 'package:flutter/material.dart';

import 'douri_colors.dart';

/// Typography system. Nexa for English, IBM Plex Sans Arabic for Arabic.
/// Never use one family for both languages — [fontFamily] picks per locale.
class AppTypography {
  const AppTypography._();

  static String fontFamily(Locale locale) {
    return locale.languageCode == 'ar' ? 'IBMPlexSansArabic' : 'Nexa';
  }

  static TextTheme textTheme(Locale locale) {
    final family = fontFamily(locale);
    return TextTheme(
      displayLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w900, fontSize: 56, height: 1.05),
      displayMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w900, fontSize: 40, height: 1.1),
      displaySmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 32, height: 1.15),
      headlineLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 24, height: 1.25),
      headlineMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 20, height: 1.3),
      headlineSmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w600, fontSize: 18, height: 1.3),
      titleLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 18, height: 1.3),
      titleMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w600, fontSize: 16, height: 1.35),
      titleSmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w500, fontSize: 14, height: 1.35),
      bodyLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w400, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w300, fontSize: 12, height: 1.45),
      labelLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 14, height: 1.2),
      labelMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w500, fontSize: 12, height: 1.2),
      labelSmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w400, fontSize: 11, height: 1.2),
    );
  }
}

/// Named text styles used by the design-system widgets, so screens don't
/// hardcode sizes/weights. All resolve the locale-correct font family.
///
/// Theme-aware (Phase 5 fix): the old version hardcoded white / #999999 /
/// lime, which broke the light theme (white text on a white card, #999999
/// at ~2.9:1 on white, lime #C8F078 at ~1.5:1 on white). Every style now
/// resolves through [BuildContext] to `context.douriColors`:
/// primary text for main copy, `textSecondary` for secondary copy.
/// `price` / `queueNumber` keep lime #C8F078 in dark theme and use a deep
/// lime in light theme — see [_accent] for the contrast reasoning.
/// Sizes, weights and line-heights are unchanged.
class DouriTextStyles {
  const DouriTextStyles._();

  /// Deep lime used ONLY for the light theme, where the brand lime
  /// #C8F078 on white is ~1.5:1 (illegible). #4E7416 on white is ~5.5:1
  /// (relative luminance ~0.142; (1.05)/(0.142+0.05) ≈ 5.48) and ~4.7:1
  /// on the light elevated surface #EDEDE7 — both ≥ 4.5:1 for normal text.
  /// In the dark theme the brand lime is kept (very high contrast on
  /// #1B1B1B cards).
  static const Color _deepLimeLight = Color(0xFF4E7416);

  static String _family(BuildContext context) =>
      AppTypography.fontFamily(Localizations.localeOf(context));

  static Color _primary(BuildContext context) => context.douriColors.text;

  static Color _secondary(BuildContext context) =>
      context.douriColors.textSecondary;

  static Color _accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFC8F078)
          : _deepLimeLight;

  static TextStyle display(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 40, height: 1.1, color: _primary(context));
  static TextStyle screenTitle(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 24, height: 1.25, color: _primary(context));
  static TextStyle sectionTitle(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 18, height: 1.3, color: _primary(context));
  static TextStyle body(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 15, height: 1.5, color: _primary(context));
  static TextStyle bodySecondary(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 14, height: 1.5, color: _secondary(context));
  static TextStyle caption(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 12, height: 1.4, color: _secondary(context));
  static TextStyle label(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w600, fontSize: 13, height: 1.3, color: _primary(context));
  static TextStyle button(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 15, height: 1.2, color: const Color(0xFF111111));
  static TextStyle price(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 16, height: 1.2, color: _accent(context));
  static TextStyle queueNumber(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 96, height: 1.0, color: _accent(context));
  static TextStyle statValue(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 28, height: 1.1, color: _primary(context));
  static TextStyle statLabel(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w500, fontSize: 12, height: 1.3, color: _secondary(context));
}

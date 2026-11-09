import 'package:flutter/material.dart';

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
class DouriTextStyles {
  const DouriTextStyles._();

  static String _family(BuildContext context) =>
      AppTypography.fontFamily(Localizations.localeOf(context));

  static TextStyle display(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 40, height: 1.1, color: Colors.white);
  static TextStyle screenTitle(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 24, height: 1.25, color: Colors.white);
  static TextStyle sectionTitle(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 18, height: 1.3, color: Colors.white);
  static TextStyle body(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 15, height: 1.5, color: Colors.white);
  static TextStyle bodySecondary(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 14, height: 1.5, color: const Color(0xFF999999));
  static TextStyle caption(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w400, fontSize: 12, height: 1.4, color: const Color(0xFF999999));
  static TextStyle label(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w600, fontSize: 13, height: 1.3, color: Colors.white);
  static TextStyle button(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 15, height: 1.2, color: const Color(0xFF111111));
  static TextStyle price(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w700, fontSize: 16, height: 1.2, color: const Color(0xFFC8F078));
  static TextStyle queueNumber(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 96, height: 1.0, color: const Color(0xFFC8F078));
  static TextStyle statValue(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w900, fontSize: 28, height: 1.1, color: Colors.white);
  static TextStyle statLabel(BuildContext context) => TextStyle(
      fontFamily: _family(context), fontWeight: FontWeight.w500, fontSize: 12, height: 1.3, color: const Color(0xFF999999));
}

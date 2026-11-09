import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static String fontFamily(Locale locale) {
    return locale.languageCode == 'ar' ? 'IBMPlexSansArabic' : 'Nexa';
  }

  static TextTheme textTheme(Locale locale) {
    final family = fontFamily(locale);
    return TextTheme(
      displayLarge: TextStyle(fontFamily: family, fontWeight: FontWeight.w900, fontSize: 40, height: 1.1),
      displayMedium: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 32, height: 1.15),
      displaySmall: TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: 28, height: 1.2),
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

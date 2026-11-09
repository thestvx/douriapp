import 'package:flutter/material.dart';

/// Theme-aware surface/text palette. The lime accent family
/// (AppColors.primaryAccent, success, warning, danger) is the same in
/// both themes; only the surfaces and text below switch.
///
/// Use `context.douriColors` inside build methods — never the dark
/// constants directly — so the light theme actually recolours the UI.
class DouriColors {
  const DouriColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.overlaySoft,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  /// Faint overlay tint for badges (white on dark, black on light).
  final Color overlaySoft;

  static const dark = DouriColors(
    background: Color(0xFF111111),
    surface: Color(0xFF171717),
    card: Color(0xFF1B1B1B),
    elevated: Color(0xFF222222),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF999999),
    textMuted: Color(0xFF686868),
    border: Color(0xFF2A2A2A),
    overlaySoft: Color(0x14FFFFFF),
  );

  static const light = DouriColors(
    background: Color(0xFFF5F5F0),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFEDEDE7),
    text: Color(0xFF111111),
    textSecondary: Color(0xFF666666),
    textMuted: Color(0xFF9A9A9A),
    border: Color(0xFFE5E5E0),
    overlaySoft: Color(0x14000000),
  );

  static DouriColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension DouriColorsX on BuildContext {
  DouriColors get douriColors => DouriColors.of(this);
}

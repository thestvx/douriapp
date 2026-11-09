import 'package:flutter/material.dart';

/// DOURI design tokens — exact palette from the redesign brief.
/// Lime (#C8F078) is the only accent and is used strategically:
/// primary actions, active navigation, queue numbers, progress.
/// Never use it as a large background fill.
class AppColors {
  const AppColors._();

  // --- Briefed palette ---
  static const Color primaryBackground = Color(0xFF111111);
  static const Color secondaryBackground = Color(0xFF171717);
  static const Color cardBackground = Color(0xFF1B1B1B);
  static const Color elevatedSurface = Color(0xFF222222);
  static const Color primaryAccent = Color(0xFFC8F078);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF999999);
  static const Color mutedText = Color(0xFF686868);
  static const Color border = Color(0xFF2A2A2A);
  static const Color success = Color(0xFF8DDC8A);
  static const Color warning = Color(0xFFF3C969);
  static const Color danger = Color(0xFFEF7777);

  // --- Legacy aliases (kept so existing code keeps compiling) ---
  static const Color white = primaryText;
  static const Color darkText = Color(0xFF111111);
  static const Color lightBackground = Color(0xFFF5F5F0);
  static const Color surface = secondaryBackground;
  static const Color onSurface = primaryText;
  static const Color muted = secondaryText;
  static const Color error = danger;

  // --- Derived, used sparingly ---
  static const Color accentOnDark = Color(0xFF111111); // text on lime
  static const Color accentSoft = Color(0x1FC8F078); // lime at ~12%
  static const Color successSoft = Color(0x1F8DDC8A);
  static const Color warningSoft = Color(0x1FF3C969);
  static const Color dangerSoft = Color(0x1FEF7777);
  static const Color whiteSoft = Color(0x14FFFFFF);
}

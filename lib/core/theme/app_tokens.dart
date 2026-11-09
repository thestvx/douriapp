import 'package:flutter/material.dart';

/// Spacing, radii, motion and elevation tokens for the DOURI design system.
/// Every screen should use these instead of ad-hoc numbers.
class DouriSpacing {
  const DouriSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double page = 20; // standard horizontal page padding
}

class DouriRadius {
  const DouriRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 20;
  static const double pill = 999;
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get sheet => const BorderRadius.vertical(top: Radius.circular(24));
}

class DouriDuration {
  const DouriDuration._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration splash = Duration(milliseconds: 1400);
}

class DouriCurves {
  const DouriCurves._();
  static const Curve standard = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOut;
  static const Curve emphasis = Curves.easeInOutCubic;
}

/// Staggered entrance delay for list item [index] (capped so long lists
/// don't keep animating forever).
Duration staggerDelay(int index) =>
    Duration(milliseconds: 40 * (index > 8 ? 8 : index));

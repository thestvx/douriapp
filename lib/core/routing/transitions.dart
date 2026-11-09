import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Page-transition builders for go_router [CustomTransitionPage].
///
/// All builders return the child unchanged under reduced motion
/// ([DouriMotion.reduced]), so the page appears immediately with no
/// transition. Transitions are interruptible by design: they are driven by
/// the route animation, so a back gesture / pop cancels them mid-flight
/// and the page is never blocked behind an animation.

enum DouriTransitionKind { slide, fade }

/// Slide in from the trailing edge + fade, 300ms, easeOutCubic.
/// Forward navigation enters from the trailing side (right in LTR, left in
/// RTL); the reverse animation runs automatically when popping.
Widget slideFadeForward(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (DouriMotion.reduced(context)) return child;
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  final dx = isRtl ? -0.25 : 0.25;
  final slide = Tween<Offset>(
    begin: Offset(dx, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: slide, child: child),
  );
}

/// Fade + slight scale (0.98 → 1.0), 250ms. For top-level / tab switches.
Widget fadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (DouriMotion.reduced(context)) return child;
  final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
  );
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: scale, child: child),
  );
}

/// Convenience wrapper: `DouriTransitionPage(kind: DouriTransitionKind.slide,
/// child: ...)`. Slide defaults to 300ms, fade to [DouriDuration.normal]
/// (250ms); both can be overridden per route.
class DouriTransitionPage<T> extends CustomTransitionPage<T> {
  DouriTransitionPage({
    super.key,
    required DouriTransitionKind kind,
    required Widget child,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
  }) : super(
         child: child,
         transitionDuration: transitionDuration ?? _durationFor(kind),
         reverseTransitionDuration:
             reverseTransitionDuration ?? _durationFor(kind),
         transitionsBuilder:
             (context, animation, secondaryAnimation, child) =>
                 _build(kind, context, animation, secondaryAnimation, child),
       );

  static Duration _durationFor(DouriTransitionKind kind) => switch (kind) {
    DouriTransitionKind.slide => const Duration(milliseconds: 300),
    DouriTransitionKind.fade => DouriDuration.normal,
  };

  static Widget _build(
    DouriTransitionKind kind,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => switch (kind) {
    DouriTransitionKind.slide => slideFadeForward(
      context,
      animation,
      secondaryAnimation,
      child,
    ),
    DouriTransitionKind.fade => fadeThrough(
      context,
      animation,
      secondaryAnimation,
      child,
    ),
  };
}

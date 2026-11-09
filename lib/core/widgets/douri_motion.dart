import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_tokens.dart';
import '../theme/douri_colors.dart';

/// Reusable motion widgets (Phase 3 foundation).
///
/// Every widget in this file respects reduced motion: when
/// [DouriMotion.reduced] is true it renders its final state immediately
/// with no animation.
///
/// Note: [showDouriSheet] already exists in `douri_feedback.dart` and is
/// deliberately NOT duplicated here. [DouriSkeleton] (opacity pulse) also
/// already exists there; [DouriShimmer] below is a different effect — a
/// sweeping gradient band — for places that need a shimmer look.

/// Fade+slide entrance for list/screen content, staggered by [index].
/// Pair with [staggerDelay] so items reveal 40ms apart (capped at 8).
class DouriStagger extends StatelessWidget {
  const DouriStagger({
    super.key,
    required this.child,
    this.index = 0,
    this.slide = true,
  });

  final Widget child;
  final int index;
  final bool slide;

  @override
  Widget build(BuildContext context) {
    if (DouriMotion.reduced(context)) return child;
    var animated = child
        .animate(delay: staggerDelay(index))
        .fadeIn(duration: DouriDuration.normal, curve: DouriCurves.entrance);
    if (slide) {
      animated = animated.slideY(
        begin: 0.08,
        end: 0,
        duration: DouriDuration.normal,
        curve: DouriCurves.entrance,
      );
    }
    return animated;
  }
}

/// Animated integer (queue numbers, stats). Counts from the previous value
/// to [value] — up or down — and renders [value] immediately under reduced
/// motion. [format] owns the display string (e.g. padLeft, locale
/// formatting); no number format is hardcoded here.
class DouriAnimatedCounter extends StatefulWidget {
  const DouriAnimatedCounter({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = DouriDuration.slow,
    this.curve = DouriCurves.standard,
  });

  final int value;

  /// Formats the displayed integer, e.g. `(v) => v.toString().padLeft(2, '0')`.
  final String Function(int value) format;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  State<DouriAnimatedCounter> createState() => _DouriAnimatedCounterState();
}

class _DouriAnimatedCounterState extends State<DouriAnimatedCounter> {
  /// The tween is stored in state and only replaced when [value] changes.
  /// A fresh `IntTween` on every build would restart the count on any
  /// unrelated parent rebuild (`TweenAnimationBuilder` compares tweens by
  /// identity). Starts at 0 so the first mount counts up; afterwards it
  /// tweens from the previous value to the new one, up or down.
  late IntTween _tween = IntTween(begin: 0, end: widget.value);

  @override
  void didUpdateWidget(covariant DouriAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _tween = IntTween(begin: oldWidget.value, end: widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DouriMotion.reduced(context)) {
      return Text(
        widget.format(widget.value),
        key: ValueKey(widget.value),
        style: widget.style,
      );
    }
    return TweenAnimationBuilder<int>(
      tween: _tween,
      duration: DouriMotion.scaled(context, widget.duration),
      curve: widget.curve,
      builder: (_, animatedValue, __) => Text(
        widget.format(animatedValue),
        key: ValueKey(widget.value),
        style: widget.style,
      ),
    );
  }
}

/// Press-scale feedback that never changes layout bounds: the scale is a
/// transform ([AnimatedScale]), so surrounding content never shifts.
/// Forwards [onTap] and guarantees a minimum 48dp hit area. Under reduced
/// motion the scale feedback is skipped entirely.
class DouriPressable extends StatefulWidget {
  const DouriPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.duration = DouriDuration.fast,
  });

  final Widget child;

  /// Null disables the control (no feedback, no tap).
  final VoidCallback? onTap;

  /// Scale while pressed (default 0.97).
  final double scale;
  final Duration duration;

  @override
  State<DouriPressable> createState() => _DouriPressableState();
}

class _DouriPressableState extends State<DouriPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduced = DouriMotion.reduced(context);
    final scale = _pressed && enabled && !reduced ? widget.scale : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: AnimatedScale(
          scale: scale,
          duration: DouriMotion.scaled(context, widget.duration),
          curve: DouriCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Status badge whose content cross-fades + scales (200ms) when it swaps.
/// Callers must give each distinct child a different [Key] (e.g.
/// `ValueKey(status)`) or the switcher has nothing to animate between.
class DouriAnimatedBadge extends StatelessWidget {
  const DouriAnimatedBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DouriMotion.reduced(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: DouriCurves.standard,
      switchOutCurve: DouriCurves.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Shimmer skeleton block: a soft highlight band sweeps across a static
/// block. One [AnimationController], disposed correctly; cheap by design
/// (a single translating gradient box, no per-frame shader rebuild).
/// Under reduced motion it renders the static block with no sweep.
/// Distinct from [DouriSkeleton] in `douri_feedback.dart`, which pulses
/// opacity instead of sweeping.
class DouriShimmer extends StatefulWidget {
  const DouriShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<DouriShimmer> createState() => _DouriShimmerState();
}

class _DouriShimmerState extends State<DouriShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Sweeps the band from off-screen start to off-screen end.
  late final Animation<double> _slide = Tween<double>(
    begin: -1.8,
    end: 1.8,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

  @override
  void initState() {
    super.initState();
    if (!DouriMotion.reduced(context)) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.douriColors;
    final base = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    // Reduced motion: static block, no sweep.
    if (DouriMotion.reduced(context)) return base;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          base,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _slide,
              builder: (_, __) => Align(
                alignment: Alignment(_slide.value, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.45,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          highlight,
                          Colors.transparent,
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'douri_button.dart';
import '../theme/douri_colors.dart';

/// Fade+slide entrance used for screen content and staggered lists.
class DouriEntrance extends StatelessWidget {
  const DouriEntrance({super.key, required this.child, this.index = 0, this.slide = true});
  final Widget child;
  final int index;
  final bool slide;

  @override
  Widget build(BuildContext context) {
    var animated = child.animate(delay: staggerDelay(index)).fadeIn(duration: DouriDuration.slow, curve: DouriCurves.entrance);
    if (slide) {
      animated = animated.slideY(begin: 0.08, end: 0, duration: DouriDuration.slow, curve: DouriCurves.entrance);
    }
    return animated;
  }
}

/// Shimmer-style skeleton block (native animation — no extra package).
class DouriSkeleton extends StatefulWidget {
  const DouriSkeleton({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<DouriSkeleton> createState() => _DouriSkeletonState();
}

class _DouriSkeletonState extends State<DouriSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 0.7).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: context.douriColors.elevated, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}

/// Skeleton list shown while shops/bookings load.
class DouriSkeletonList extends StatelessWidget {
  const DouriSkeletonList({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: DouriSpacing.md),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DouriSkeleton(height: 120, radius: 18),
          SizedBox(height: 10),
          DouriSkeleton(width: 160),
          SizedBox(height: 6),
          DouriSkeleton(width: 110),
        ],
      ),
    );
  }
}

/// Designed empty state — used instead of fake/placeholder data.
class DouriEmptyState extends StatelessWidget {
  const DouriEmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DouriSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.douriColors.elevated, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: DouriTextStyles.accent(context)),
            ),
            SizedBox(height: DouriSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: DouriSpacing.sm),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.douriColors.textSecondary), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: DouriSpacing.xl),
              DouriButton(label: actionLabel!, onPressed: onAction, variant: DouriButtonVariant.secondary, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Designed error state with retry.
class DouriErrorState extends StatelessWidget {
  const DouriErrorState({super.key, required this.message, required this.onRetry, this.title});
  final String message;
  final VoidCallback onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DouriSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            SizedBox(height: DouriSpacing.lg),
            Text(title ?? l10n.error, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: DouriSpacing.sm),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.douriColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: DouriSpacing.xl),
            DouriButton(label: l10n.retry, onPressed: onRetry, variant: DouriButtonVariant.secondary, expanded: false),
          ],
        ),
      ),
    );
  }
}

/// Animated linear progress (queue progress, booking steps).
class DouriProgress extends StatelessWidget {
  const DouriProgress({super.key, required this.value, this.height = 6});
  final double value; // 0..1
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
        duration: DouriDuration.slow,
        curve: DouriCurves.emphasis,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: context.douriColors.elevated,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        ),
      ),
    );
  }
}

/// Animated queue number: slides/fades when the number changes.
class DouriQueueNumber extends StatelessWidget {
  const DouriQueueNumber({super.key, required this.number, this.fontSize = 96});
  final int number;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: DouriDuration.normal,
      switchInCurve: DouriCurves.standard,
      switchOutCurve: DouriCurves.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation), child: child),
      ),
      child: Text(
        number.toString().padLeft(2, '0'),
        key: ValueKey(number),
        style: DouriTextStyles.queueNumber(
          context,
        ).copyWith(fontSize: fontSize, height: 1),
      ),
    );
  }
}

/// Premium bottom sheet with a drag handle.
Future<T?> showDouriSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.douriColors.elevated,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.douriColors.border, borderRadius: BorderRadius.circular(2))),
            Flexible(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(DouriSpacing.xl), child: child))),
          ],
        ),
      ),
    ),
  );
}

/// Confirmation dialog — used before destructive/queue actions.
Future<bool> showDouriConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.douriColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel, style: TextStyle(color: destructive ? AppColors.danger : DouriTextStyles.accent(context))),
        ),
      ],
    ),
  );
  return result ?? false;
}

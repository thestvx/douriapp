import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/douri_colors.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/queue_entry.dart';
import '../home/shop_providers.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingSuccess)),
      body: FutureBuilder(
        future: ref.read(bookingRepositoryProvider).getBooking(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(DouriSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DouriSpacing.xl),
                  const Center(
                    child: DouriSkeleton(width: 120, height: 120, radius: 60),
                  ),
                  const SizedBox(height: DouriSpacing.xl),
                  const Center(
                    child: DouriSkeleton(width: 220, height: 24),
                  ),
                  const SizedBox(height: DouriSpacing.sm),
                  const Center(
                    child: DouriSkeleton(width: 280, height: 16),
                  ),
                  const SizedBox(height: DouriSpacing.xxl),
                  const DouriSkeleton(height: 180, radius: 18),
                  const SizedBox(height: DouriSpacing.lg),
                  const DouriSkeleton(height: 110, radius: 18),
                ],
              ),
            );
          }
          final booking = snapshot.data;
          if (booking == null) {
            return DouriStagger(
              child: DouriEmptyState(
                icon: Icons.calendar_today_outlined,
                title: l10n.noBookings,
                message: l10n.noBookingsMessage,
              ),
            );
          }
          final shopAsync = ref.watch(shopByIdProvider(booking.barberShopId));
          final d = booking.bookingDate;
          final refShort = booking.id.length > 8
              ? booking.id.substring(0, 8).toUpperCase()
              : booking.id.toUpperCase();
          // Live queue number: the booking starts PENDING with no number.
          // The moment the barber accepts it, approve_booking creates a
          // queue entry and this stream delivers the number here — no
          // refresh needed, and no number is ever shown before acceptance.
          return StreamBuilder<QueueEntry?>(
            stream: ref
                .read(queueRepositoryProvider)
                .watchEntryForBooking(booking.id),
            builder: (context, entrySnapshot) {
              final queueNumber =
                  entrySnapshot.data?.queueNumber ?? booking.queueNumber;
              final confirmed = queueNumber != null;
              return SingleChildScrollView(
            padding: const EdgeInsets.all(DouriSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: DouriSpacing.xl),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSoft,
                      border: Border.all(color: AppColors.primaryAccent, width: 1.5),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 56,
                      color: DouriTextStyles.accent(context),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: DouriDuration.slow,
                      curve: DouriCurves.emphasis,
                    )
                    .fadeIn(duration: DouriDuration.slow),
                SizedBox(height: DouriSpacing.xl),
                DouriStagger(
                  child: Text(
                    l10n.bookingSuccess,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 1,
                  child: Text(
                    l10n.bookingSuccessMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: DouriSpacing.lg),
                // Pending vs confirmed is distinct at a glance: a
                // warning pill while waiting, a success pill once the
                // barber accepts. It cross-fades the moment the live
                // stream delivers the queue number.
                DouriStagger(
                  index: 2,
                  child: Center(
                    child: DouriAnimatedBadge(
                      child: Container(
                        key: ValueKey(confirmed ? 'confirmed' : 'pending'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DouriSpacing.md,
                          vertical: DouriSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: confirmed
                              ? AppColors.successSoft
                              : AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(DouriRadius.pill),
                          border: Border.all(
                            color: confirmed
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              confirmed
                                  ? Icons.check_circle
                                  : Icons.hourglass_top,
                              size: 16,
                              color: confirmed
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: DouriSpacing.sm),
                            Text(
                              confirmed
                                  ? l10n.bookingConfirmed
                                  : l10n.bookingPending,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: confirmed
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.lg),
                DouriStagger(
                  index: 3,
                  child: DouriCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row(
                          label: l10n.bookingReference,
                          value: refShort,
                          valueColor: AppColors.primaryAccent,
                          ltrValue: true,
                        ),
                        _Row(
                          label: l10n.shopName,
                          value: shopAsync.value?.shopName ?? '—',
                        ),
                        _Row(
                          label: l10n.date,
                          value: '${d.day}/${d.month}/${d.year}',
                          ltrValue: true,
                        ),
                        _Row(label: l10n.time, value: booking.bookingTime, ltrValue: true),
                        _Row(
                          label: l10n.notifyOnPhone,
                          value: booking.customerPhone,
                          ltrValue: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: DouriSpacing.lg),
                // The number card and the pending banner swap with a
                // cross-fade the moment acceptance arrives live.
                AnimatedSwitcher(
                  duration: DouriMotion.scaled(context, DouriDuration.normal),
                  switchInCurve: DouriCurves.standard,
                  switchOutCurve: DouriCurves.standard,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: queueNumber != null
                      ? DouriStagger(
                          key: const ValueKey('number'),
                          index: 4,
                          child: DouriCard(
                            child: Column(
                              children: [
                                Text(
                                  l10n.yourQueueNumber,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: context.douriColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: DouriSpacing.sm),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: DouriAnimatedCounter(
                                    value: queueNumber,
                                    format: (v) => v.toString().padLeft(2, '0'),
                                    style: DouriTextStyles.queueNumber(context),
                                  ),
                                ),
                                const SizedBox(height: DouriSpacing.sm),
                                Text(
                                  l10n.queueNumberAfterApproval,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.douriColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : DouriStagger(
                          key: const ValueKey('pending'),
                          index: 4,
                          child: Container(
                            padding: const EdgeInsets.all(DouriSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.warningSoft,
                              borderRadius: DouriRadius.card,
                              border: Border.all(color: context.douriColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_top, color: AppColors.warning),
                                const SizedBox(width: DouriSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.pendingApproval,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: AppColors.warning,
                                            ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        l10n.queueNumberAfterApproval,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: context.douriColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriStagger(
                  index: 5,
                  child: DouriButton(
                    label: l10n.backToHome,
                    onPressed: () => context.go('/customer'),
                  ),
                ),
                const SizedBox(height: DouriSpacing.md),
                DouriStagger(
                  index: 6,
                  child: DouriButton(
                    label: l10n.trackQueue,
                    variant: DouriButtonVariant.secondary,
                    onPressed: queueNumber == null
                        ? null
                        : () => context.push(
                              '/queue/$queueNumber?bookingId=${booking.id}',
                            ),
                  ),
                ),
                if (queueNumber == null) ...[
                  SizedBox(height: DouriSpacing.sm),
                  Text(
                    l10n.queueNumberAfterApproval,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.douriColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.ltrValue = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool ltrValue;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
          ),
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: DouriSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.douriColors.textSecondary,
                ),
          ),
          const Spacer(),
          Flexible(
            child: ltrValue
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: valueText,
                  )
                : valueText,
          ),
        ],
      ),
    );
  }
}

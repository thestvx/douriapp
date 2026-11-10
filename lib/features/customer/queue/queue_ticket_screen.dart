import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/queue_entry.dart';
import '../home/shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

/// Live stream of one booking's queue entry (null until the barber accepts).
final _entryProvider = StreamProvider.family<QueueEntry?, String>((ref, bookingId) {
  return ref.read(queueRepositoryProvider).watchEntryForBooking(bookingId);
});

class QueueTicketScreen extends ConsumerWidget {
  const QueueTicketScreen({super.key, required this.queueNumber, this.bookingId});
  final int queueNumber;
  final String? bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (bookingId != null) {
      return _TicketView(bookingId: bookingId!, fallbackNumber: queueNumber);
    }
    return FutureBuilder<Booking?>(
      future: ref.read(bookingRepositoryProvider).getBookingByQueueNumber(queueNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.queueTitle)),
            body: const _TicketSkeleton(),
          );
        }
        final booking = snapshot.data;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.queueTitle)),
            body: DouriStagger(
              child: DouriEmptyState(
                icon: Icons.queue_outlined,
                title: l10n.noActiveQueue,
                message: l10n.noActiveQueueMessage,
              ),
            ),
          );
        }
        return _TicketView(bookingId: booking.id, fallbackNumber: queueNumber);
      },
    );
  }
}

class _TicketView extends ConsumerWidget {
  const _TicketView({required this.bookingId, required this.fallbackNumber});
  final String bookingId;
  final int fallbackNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entryAsync = ref.watch(_entryProvider(bookingId));
    final entry = entryAsync.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.queueTitle)),
      body: FutureBuilder<Booking?>(
        future: ref.read(bookingRepositoryProvider).getBooking(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _TicketSkeleton();
          }
          final booking = snapshot.data;
          if (booking == null) {
            return DouriStagger(
              child: DouriEmptyState(
                icon: Icons.queue_outlined,
                title: l10n.noActiveQueue,
                message: l10n.noActiveQueueMessage,
              ),
            );
          }
          return _TicketLoaded(
            booking: booking,
            entry: entry,
            fallbackNumber: fallbackNumber,
          );
        },
      ),
    );
  }
}

/// Skeleton shown while the ticket loads: a hero block plus the info
/// card, matching the loaded layout's shapes.
class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(DouriSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DouriSkeleton(height: 250, radius: 18),
          SizedBox(height: DouriSpacing.lg),
          DouriSkeleton(height: 210, radius: 18),
        ],
      ),
    );
  }
}

class _TicketLoaded extends ConsumerWidget {
  const _TicketLoaded({
    required this.booking,
    required this.entry,
    required this.fallbackNumber,
  });
  final Booking booking;
  final QueueEntry? entry;
  final int fallbackNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final number = entry?.queueNumber ?? booking.queueNumber ?? fallbackNumber;
    final status = entry?.status ?? booking.status;
    final (label, color) = _statusLabelColor(context, l10n, status);
    final isApproaching = status == 'APPROACHING' || status == 'CURRENT';
    final shopAsync = ref.watch(shopByIdProvider(booking.barberShopId));
    final shop = shopAsync.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DouriSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DouriStagger(
            child: AnimatedContainer(
              duration: DouriDuration.normal,
              curve: DouriCurves.standard,
              padding: const EdgeInsets.all(DouriSpacing.xxl),
              decoration: BoxDecoration(
                color: isApproaching ? AppColors.accentSoft : context.douriColors.card,
                borderRadius: DouriRadius.card,
                border: Border.all(
                  color: isApproaching ? AppColors.primaryAccent : context.douriColors.border,
                  width: isApproaching ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(l10n.queueNumber, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: DouriSpacing.sm),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: DouriAnimatedCounter(
                      value: number,
                      format: (v) => v.toString().padLeft(2, '0'),
                      style: DouriTextStyles.queueNumber(context),
                    ),
                  ),
                  const SizedBox(height: DouriSpacing.md),
                  DouriAnimatedBadge(
                    child: Container(
                      key: ValueKey(status),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
                      ),
                    ),
                  ),
                  SizedBox(height: DouriSpacing.sm),
                  Text(
                    shop?.shopName ?? booking.customerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DouriSpacing.lg),
          if (shop != null)
            DouriStagger(
              index: 1,
              child: FutureBuilder<({int ahead, int? nowServing})>(
                future: _loadQueueInfo(ref, shop.id, number),
                builder: (_, snapshot) {
                  final ahead = snapshot.data?.ahead ?? 0;
                  final nowServing = snapshot.data?.nowServing;
                  final waitMinutes = ahead * shop.appointmentDuration;
                  final progress = status == 'CURRENT'
                      ? 1.0
                      : nowServing == null
                          ? 0.0
                          : (nowServing / number).clamp(0.0, 1.0);
                  return DouriCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.nowServing,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.douriColors.textSecondary,
                                  ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: DouriMotion.scaled(
                                  context, DouriDuration.normal),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Directionality(
                                key: ValueKey(nowServing),
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  nowServing == null ? '—' : '#$nowServing',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppColors.primaryAccent,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DouriSpacing.lg),
                        Row(
                          children: [
                            Text(
                              l10n.peopleAhead,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.douriColors.textSecondary,
                                  ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: DouriMotion.scaled(
                                  context, DouriDuration.normal),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Directionality(
                                key: ValueKey(ahead),
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '$ahead',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DouriSpacing.md),
                        Row(
                          children: [
                            Text(
                              l10n.estimatedWait,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.douriColors.textSecondary,
                                  ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: DouriMotion.scaled(
                                  context, DouriDuration.normal),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                '$waitMinutes ${l10n.minutes}',
                                key: ValueKey(waitMinutes),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DouriSpacing.lg),
                        Text(
                          l10n.yourPosition,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.douriColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: DouriSpacing.sm),
                        DouriProgress(value: progress),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (booking.queueNumber == null && entry == null) ...[
            SizedBox(height: DouriSpacing.lg),
            DouriStagger(
              index: 2,
              child: Text(
                l10n.queueNumberAfterApproval,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.douriColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: DouriSpacing.xxl),
          if (booking.status == 'PENDING' || booking.status == 'CONFIRMED')
            DouriStagger(
              index: 3,
              child: DouriButton(
                label: l10n.leaveQueue,
                variant: DouriButtonVariant.danger,
                onPressed: () async {
                  final confirmed = await showDouriConfirm(
                    context,
                    title: l10n.confirmLeaveQueue,
                    message: l10n.confirmLeaveQueueMsg,
                    confirmLabel: l10n.leaveQueue,
                    destructive: true,
                  );
                  if (!confirmed) return;
                  try {
                    await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
                    if (context.mounted) context.go('/customer');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.actionFailed)),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<({int ahead, int? nowServing})> _loadQueueInfo(
    WidgetRef ref,
    String shopId,
    int number,
  ) async {
    final queueRepo = ref.read(queueRepositoryProvider);
    final queue = await queueRepo.getTodayQueue(shopId);
    final ahead = await queueRepo.countAhead(shopId, number);
    return (ahead: ahead, nowServing: queue?['current_queue_number'] as int?);
  }
}

(String, Color) _statusLabelColor(
    BuildContext context, AppLocalizations l10n, String status) {
  switch (status) {
    case 'WAITING':
      return (l10n.queueWaiting, context.douriColors.textSecondary);
    case 'APPROACHING':
      return (l10n.queueApproaching, AppColors.primaryAccent);
    case 'CURRENT':
      return (l10n.queueCurrent, AppColors.primaryAccent);
    case 'COMPLETED':
      return (l10n.queueCompleted, AppColors.success);
    case 'SKIPPED':
      return (l10n.queueSkipped, AppColors.warning);
    case 'CANCELLED':
      return (l10n.queueCancelled, AppColors.danger);
    case 'PENDING':
      return (l10n.bookingPending, AppColors.warning);
    case 'CONFIRMED':
      return (l10n.bookingConfirmed, AppColors.success);
    case 'REJECTED':
      return (l10n.bookingRejected, AppColors.danger);
    default:
      return (status, context.douriColors.textSecondary);
  }
}

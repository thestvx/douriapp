import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            );
          }
          final booking = snapshot.data;
          if (booking == null) {
            return DouriEmptyState(
              icon: Icons.calendar_today_outlined,
              title: l10n.noBookings,
              message: l10n.noBookingsMessage,
            );
          }
          final shopAsync = ref.watch(shopByIdProvider(booking.barberShopId));
          final d = booking.bookingDate;
          final refShort = booking.id.length > 8
              ? booking.id.substring(0, 8).toUpperCase()
              : booking.id.toUpperCase();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(DouriSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: DouriSpacing.xl),
                const Icon(
                  Icons.check_circle,
                  size: 88,
                  color: AppColors.primaryAccent,
                )
                    .animate()
                    .scale(
                      duration: DouriDuration.slow,
                      curve: DouriCurves.emphasis,
                    )
                    .fadeIn(duration: DouriDuration.slow),
                const SizedBox(height: DouriSpacing.xl),
                DouriEntrance(
                  child: Text(
                    l10n.bookingSuccess,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: DouriSpacing.sm),
                DouriEntrance(
                  index: 1,
                  child: Text(
                    l10n.bookingSuccessMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriEntrance(
                  index: 2,
                  child: DouriCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row(
                          label: l10n.bookingReference,
                          value: refShort,
                          valueColor: AppColors.primaryAccent,
                        ),
                        _Row(
                          label: l10n.shopName,
                          value: shopAsync.valueOrNull?.shopName ?? '—',
                        ),
                        _Row(
                          label: l10n.date,
                          value: '${d.day}/${d.month}/${d.year}',
                        ),
                        _Row(label: l10n.time, value: booking.bookingTime),
                        _Row(label: l10n.status, value: l10n.bookingPending),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.lg),
                DouriEntrance(
                  index: 3,
                  child: Container(
                    padding: const EdgeInsets.all(DouriSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: DouriRadius.card,
                      border: Border.all(color: AppColors.border),
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
                              const SizedBox(height: 2),
                              Text(
                                l10n.queueNumberAfterApproval,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriEntrance(
                  index: 4,
                  child: DouriButton(
                    label: l10n.backToHome,
                    onPressed: () => context.go('/customer'),
                  ),
                ),
                const SizedBox(height: DouriSpacing.md),
                DouriEntrance(
                  index: 5,
                  child: DouriButton(
                    label: l10n.trackQueue,
                    variant: DouriButtonVariant.secondary,
                    onPressed: booking.queueNumber == null
                        ? null
                        : () => context.go(
                              '/queue/${booking.queueNumber}?bookingId=${booking.id}',
                            ),
                  ),
                ),
                if (booking.queueNumber == null) ...[
                  const SizedBox(height: DouriSpacing.sm),
                  Text(
                    l10n.queueNumberAfterApproval,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DouriSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

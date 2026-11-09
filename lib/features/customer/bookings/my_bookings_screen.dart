import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../shared/models/booking.dart';
import '../../authentication/auth_providers.dart';
import '../home/shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'PENDING':
      return AppColors.warning;
    case 'CONFIRMED':
      return AppColors.success;
    case 'REJECTED':
    case 'CANCELLED':
      return AppColors.danger;
    case 'COMPLETED':
      return context.douriColors.textSecondary;
    default:
      return context.douriColors.textSecondary;
  }
}

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'PENDING':
      return l10n.bookingPending;
    case 'CONFIRMED':
      return l10n.bookingConfirmed;
    case 'REJECTED':
      return l10n.bookingRejected;
    case 'CANCELLED':
      return l10n.bookingCancelled;
    case 'COMPLETED':
      return l10n.bookingCompleted;
    default:
      return status;
  }
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);

    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DouriSpacing.page,
                DouriSpacing.sm,
                DouriSpacing.page,
                0,
              ),
              child: Text(l10n.myBookings, style: Theme.of(context).textTheme.headlineMedium),
            ),
            SizedBox(height: DouriSpacing.md),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primaryAccent,
              labelColor: AppColors.primaryAccent,
              unselectedLabelColor: context.douriColors.textSecondary,
              tabs: [
                Tab(text: l10n.upcoming),
                Tab(text: l10n.pending),
                Tab(text: l10n.completed),
                Tab(text: l10n.cancelled),
              ],
            ),
            Expanded(
              child: auth.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(DouriSpacing.page),
                  child: DouriSkeletonList(),
                ),
                error: (_, __) => DouriEmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: l10n.noBookings,
                  message: l10n.noBookingsMessage,
                ),
                data: (user) {
                  final uid = user?.uid;
                  if (uid == null) {
                    return DouriEmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.noBookings,
                      message: l10n.noBookingsMessage,
                    );
                  }
                  final bookingsAsync = ref.watch(customerBookingsProvider(uid));
                  return bookingsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(DouriSpacing.page),
                      child: DouriSkeletonList(),
                    ),
                    error: (e, _) => DouriErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(customerBookingsProvider(uid)),
                    ),
                    data: (bookings) {
                      final upcoming = bookings
                          .where((b) => b.status == 'PENDING' || b.status == 'CONFIRMED')
                          .toList();
                      final pending =
                          bookings.where((b) => b.status == 'PENDING').toList();
                      final completed =
                          bookings.where((b) => b.status == 'COMPLETED').toList();
                      final cancelled = bookings
                          .where((b) => b.status == 'CANCELLED' || b.status == 'REJECTED')
                          .toList();
                      return TabBarView(
                        children: [
                          _BookingsList(bookings: upcoming, uid: uid),
                          _BookingsList(bookings: pending, uid: uid),
                          _BookingsList(bookings: completed, uid: uid),
                          _BookingsList(bookings: cancelled, uid: uid),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  const _BookingsList({required this.bookings, required this.uid});
  final List<Booking> bookings;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (bookings.isEmpty) {
      return DouriEmptyState(
        icon: Icons.calendar_today_outlined,
        title: l10n.noBookings,
        message: l10n.noBookingsMessage,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(customerBookingsProvider(uid)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DouriSpacing.page),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: DouriSpacing.md),
        itemBuilder: (_, i) => DouriEntrance(
          index: i,
          child: _BookingRow(booking: bookings[i]),
        ),
      ),
    );
  }
}

class _BookingRow extends ConsumerWidget {
  const _BookingRow({required this.booking});
  final Booking booking;

  void _open(BuildContext context) {
    if (booking.queueNumber != null) {
      context.push('/queue/${booking.queueNumber}?bookingId=${booking.id}');
    } else {
      context.push('/booking-success/${booking.id}');
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDouriConfirm(
      context,
      title: l10n.cancel,
      message: l10n.confirmDeleteMsg,
      confirmLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shop = ref.watch(shopByIdProvider(booking.barberShopId)).value;
    final d = booking.bookingDate;
    final cancellable = booking.status == 'PENDING' || booking.status == 'CONFIRMED';
    return DouriBookingCard(
      title: shop?.shopName ?? booking.customerName,
      subtitle: booking.customerName,
      statusLabel: _statusLabel(l10n, booking.status),
      statusColor: _statusColor(context, booking.status),
      queueNumber: booking.queueNumber,
      dateLabel: '${d.day}/${d.month}/${d.year}',
      timeLabel: booking.bookingTime,
      onTap: () => _open(context),
      actions: cancellable
          ? [
              DouriButton(
                label: l10n.cancel,
                variant: DouriButtonVariant.danger,
                expanded: false,
                onPressed: () => _cancel(context, ref),
              ),
            ]
          : null,
    );
  }
}

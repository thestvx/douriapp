import 'package:flutter/material.dart';
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
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/queue_entry.dart';
import '../booking_requests/booking_requests_screen.dart';
import '../profile/barber_profile_screen.dart';
import '../queue_management/queue_management_screen.dart';
import 'shop_provider.dart';

class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});
  @override
  ConsumerState<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends ConsumerState<BarberDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopAsync = ref.watch(currentShopProvider);
    final shop = shopAsync.value;
    return Scaffold(
      backgroundColor: context.douriColors.background,
      appBar: DouriAppBar(title: shop?.shopName ?? l10n.dashboard),
      body: shopAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(DouriSpacing.page),
          child: DouriSkeletonList(),
        ),
        error: (e, __) => DouriErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentShopProvider),
        ),
        data: (shop) {
          if (shop == null) {
            return DouriEmptyState(
              icon: Icons.store_outlined,
              title: l10n.noShopYet,
              message: l10n.noShopMessage,
              actionLabel: l10n.createShop,
              onAction: () => context.push('/barber/shop'),
            );
          }
          return IndexedStack(
            index: _index,
            children: [
              _DashboardBody(
                shop: shop,
                onGoToQueue: () => setState(() => _index = 1),
                onGoToBookings: () => setState(() => _index = 2),
                onGoToProfile: () => setState(() => _index = 3),
              ),
              QueueManagementScreen(shopId: shop.id),
              BookingRequestsScreen(shopId: shop.id),
              BarberProfileScreen(onManageShop: () => context.push('/barber/shop')),
            ],
          );
        },
      ),
      bottomNavigationBar: DouriBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          DouriNavItem(icon: Icons.dashboard_outlined, label: l10n.dashboard),
          DouriNavItem(icon: Icons.people_outline, label: l10n.queueManagement),
          DouriNavItem(icon: Icons.inbox_outlined, label: l10n.bookingRequests),
          DouriNavItem(icon: Icons.person_outline, label: l10n.profile),
        ],
      ),
    );
  }
}

class _DayStats {
  const _DayStats({
    required this.todayBookings,
    required this.waiting,
    required this.currentNumber,
    required this.completed,
    required this.total,
    this.currentName,
    this.currentBookingTime,
    this.nextNumber = 0,
    this.nextName,
    this.nextBookingTime,
  });

  final int todayBookings;
  final int waiting;
  final int currentNumber; // 0 when nobody is being served
  final int completed;

  /// All of today's queue entries (waiting + current + completed +
  /// skipped). Drives the queue progress bar.
  final int total;

  /// Who is being served now, if anyone. Name/time come from the
  /// bookings join in [QueueEntry]; there is no service field anywhere
  /// in the data layer, so no service is ever shown.
  final String? currentName;
  final String? currentBookingTime;

  /// First waiting/approaching entry after the current one, if any.
  final int nextNumber;
  final String? nextName;
  final String? nextBookingTime;
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  final local = d.toLocal();
  return local.year == now.year && local.month == now.month && local.day == now.day;
}

class _DashboardBody extends ConsumerStatefulWidget {
  const _DashboardBody({
    required this.shop,
    required this.onGoToQueue,
    required this.onGoToBookings,
    required this.onGoToProfile,
  });

  final BarberShop shop;
  final VoidCallback onGoToQueue;
  final VoidCallback onGoToBookings;
  final VoidCallback onGoToProfile;

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  late Future<_DayStats> _statsFuture;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  @override
  void didUpdateWidget(covariant _DashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id) {
      _statsFuture = _loadStats();
    }
  }

  Future<_DayStats> _loadStats() async {
    final bookings =
        await ref.read(bookingRepositoryProvider).getShopBookings(widget.shop.id);
    final entries = await ref.read(queueRepositoryProvider).listTodayEntries(widget.shop.id);
    QueueEntry? current;
    for (final e in entries) {
      if (e.isCurrent) {
        current = e;
        break;
      }
    }
    QueueEntry? next;
    for (final e in entries) {
      if (e.isWaiting || e.isApproaching) {
        next = e;
        break;
      }
    }
    return _DayStats(
      todayBookings: bookings.where((Booking b) => _isToday(b.bookingDate)).length,
      waiting: entries.where((e) => e.isWaiting || e.isApproaching).length,
      currentNumber: current?.queueNumber ?? 0,
      completed: entries.where((e) => e.isCompleted).length,
      total: entries.length,
      currentName: current?.customerName,
      currentBookingTime: current?.bookingTime,
      nextNumber: next?.queueNumber ?? 0,
      nextName: next?.customerName,
      nextBookingTime: next?.bookingTime,
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(currentShopProvider);
    final future = _loadStats();
    setState(() => _statsFuture = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder shows the error state; pull-to-refresh just ends.
    }
  }

  Future<void> _toggleOpen(bool value) async {
    setState(() => _toggling = true);
    try {
      await ref.read(barberShopRepositoryProvider).upsertShop({
        'id': widget.shop.id,
        'is_open': value,
      });
      ref.invalidate(currentShopProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final shop = widget.shop;
    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: context.douriColors.elevated,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DouriSpacing.page,
          DouriSpacing.page,
          DouriSpacing.page,
          116,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Below ~360dp of content width the two-column grids get
            // taller cells so two-line labels never clip.
            final narrow = constraints.maxWidth < 360;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0 — Compact header: greeting + shop name + date line
                // with the open/closed badge inline, avatar on the end
                // jumping to the existing profile tab.
                DouriStagger(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.hello,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: context.douriColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shop.shopName,
                              style: Theme.of(context).textTheme.headlineMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${now.day}/${now.month}/${now.year}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: DouriSpacing.sm),
                                DouriStatusBadge(open: shop.isOpen),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DouriSpacing.md),
                      Semantics(
                        button: true,
                        label: l10n.profile,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onGoToProfile,
                            child: DouriAvatar(
                              name: shop.shopName,
                              imageUrl: shop.logoUrl,
                              radius: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DouriSpacing.lg),
                // 1 — Workday status hero: animated dot + label that
                // cross-fades on change, real one-line summary
                // (appointment length is a real BarberShop field),
                // Switch kept as the control with the original logic.
                DouriStagger(
                  index: 1,
                  child: DouriCard(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: shop.isOpen
                                ? AppColors.accentSoft
                                : context.douriColors.overlaySoft,
                          ),
                          child: AnimatedContainer(
                            duration: DouriDuration.normal,
                            curve: DouriCurves.standard,
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: shop.isOpen
                                  ? AppColors.success
                                  : context.douriColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: DouriSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DouriAnimatedBadge(
                                child: Text(
                                  shop.isOpen ? l10n.shopOpen : l10n.shopClosed,
                                  key: ValueKey(shop.isOpen),
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${shop.appointmentDuration} ${l10n.minutesShort}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: context.douriColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: shop.isOpen,
                          onChanged: _toggling ? null : _toggleOpen,
                          activeColor: AppColors.primaryAccent,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xl),
                FutureBuilder<_DayStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const DouriSkeletonList(itemCount: 2);
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return DouriErrorState(
                        message: l10n.actionFailed,
                        onRetry: () => setState(() => _statsFuture = _loadStats()),
                      );
                    }
                    final stats = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2 — Live queue section header.
                        DouriStagger(
                          index: 2,
                          child: DouriSectionHeader(
                            title: l10n.liveQueue,
                            actionLabel: l10n.viewQueue,
                            onAction: widget.onGoToQueue,
                          ),
                        ),
                        const SizedBox(height: DouriSpacing.md),
                        // 3 — Live queue hero card (taps through to the
                        // queue tab, which owns start/advance/end).
                        DouriStagger(
                          index: 3,
                          child: _LiveQueueHero(
                            stats: stats,
                            appointmentDuration: shop.appointmentDuration,
                            onGoToQueue: widget.onGoToQueue,
                          ),
                        ),
                        const SizedBox(height: DouriSpacing.xl),
                        // 4 — Statistics: same 4 KPIs, restyled with
                        // lime-tinted icon chips + animated counters.
                        DouriStagger(
                          index: 4,
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: DouriSpacing.md,
                            crossAxisSpacing: DouriSpacing.md,
                            childAspectRatio: narrow ? 1.0 : 1.15,
                            children: [
                              _StatCard(
                                value: stats.todayBookings,
                                label: l10n.todaysBookings,
                                icon: Icons.calendar_today_outlined,
                              ),
                              _StatCard(
                                value: stats.waiting,
                                label: l10n.waitingCustomers,
                                icon: Icons.people_outline,
                              ),
                              _StatCard(
                                value: stats.currentNumber,
                                label: l10n.currentCustomer,
                                icon: Icons.person_outline,
                                isQueueNumber: true,
                              ),
                              _StatCard(
                                value: stats.completed,
                                label: l10n.completedToday,
                                icon: Icons.check_circle_outline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DouriSpacing.xl),
                        // 5 — Quick actions header + 2x2 pressable grid.
                        DouriStagger(
                          index: 5,
                          child: DouriSectionHeader(title: l10n.quickActions),
                        ),
                        const SizedBox(height: DouriSpacing.md),
                        DouriStagger(
                          index: 6,
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: DouriSpacing.md,
                            crossAxisSpacing: DouriSpacing.md,
                            childAspectRatio: narrow ? 1.9 : 2.2,
                            children: [
                              _QuickActionCard(
                                icon: Icons.play_circle_outline,
                                label: l10n.startDay,
                                onTap: widget.onGoToQueue,
                              ),
                              _QuickActionCard(
                                icon: Icons.people_outline,
                                label: l10n.queueManagement,
                                onTap: widget.onGoToQueue,
                              ),
                              _QuickActionCard(
                                icon: Icons.inbox_outlined,
                                label: l10n.bookingRequests,
                                onTap: widget.onGoToBookings,
                              ),
                              _QuickActionCard(
                                icon: Icons.store_outlined,
                                label: l10n.shopManagement,
                                onTap: () => context.push('/barber/shop'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Central live-queue hero. Shows the number being served (or the next
/// number when nobody is being served yet) huge in lime, the customer's
/// real name + booking time when the join provides them, the next
/// customer, a completed/total progress bar, and an estimated wait
/// derived only from real data (waiting count x appointment length).
/// Never invents a name, a service, or a wait time. Empty state lives
/// inside the card when no queue is running today.
class _LiveQueueHero extends StatelessWidget {
  const _LiveQueueHero({
    required this.stats,
    required this.appointmentDuration,
    required this.onGoToQueue,
  });

  final _DayStats stats;
  final int appointmentDuration;
  final VoidCallback onGoToQueue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (stats.total == 0) {
      return DouriCard(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.douriColors.elevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 32,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
            Text(
              l10n.noCustomersYet,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DouriSpacing.sm),
            Text(
              l10n.noCustomersYetMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.douriColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriButton(
              label: l10n.startDay,
              icon: Icons.play_arrow_rounded,
              variant: DouriButtonVariant.secondary,
              expanded: false,
              onPressed: onGoToQueue,
            ),
          ],
        ),
      );
    }

    final hasCurrent = stats.currentNumber != 0;
    final heroNumber = hasCurrent ? stats.currentNumber : stats.nextNumber;
    final heroName = hasCurrent ? stats.currentName : stats.nextName;
    final heroTime =
        hasCurrent ? stats.currentBookingTime : stats.nextBookingTime;
    final hasNext = hasCurrent && stats.nextNumber != 0;
    final progress =
        stats.total == 0 ? 0.0 : stats.completed / stats.total;

    return DouriCard(
      onTap: onGoToQueue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DouriAnimatedCounter(
                value: heroNumber,
                format: (v) => v.toString().padLeft(2, '0'),
                style: DouriTextStyles.queueNumber(context),
              ),
              const SizedBox(width: DouriSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCurrent ? l10n.nowServing : l10n.nextCustomer,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.douriColors.textSecondary,
                          ),
                    ),
                    if (heroName != null && heroName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        heroName,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (heroTime != null && heroTime.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: context.douriColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              heroTime,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: context.douriColors.textMuted,
              ),
            ],
          ),
          if (hasNext) ...[
            const SizedBox(height: DouriSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DouriSpacing.md,
                vertical: DouriSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.douriColors.elevated,
                borderRadius: BorderRadius.circular(DouriRadius.md),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.nextCustomer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: DouriSpacing.sm),
                  Expanded(
                    child: Text(
                      stats.nextName != null && stats.nextName!.isNotEmpty
                          ? '#${stats.nextNumber} · ${stats.nextName}'
                          : '#${stats.nextNumber}',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DouriSpacing.lg),
          DouriProgress(value: progress),
          const SizedBox(height: DouriSpacing.sm),
          Wrap(
            spacing: DouriSpacing.xl,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.queueProgress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.completed}/${stats.total}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (stats.waiting > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.estimatedWait,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.douriColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~${stats.waiting * appointmentDuration} ${l10n.minutesShort}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.isQueueNumber = false,
  });

  final int value;
  final String label;
  final IconData icon;

  /// Current-customer card: shows '#05', or '—' when nobody is served.
  final bool isQueueNumber;

  @override
  Widget build(BuildContext context) {
    return DouriCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(DouriRadius.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryAccent),
          ),
          const SizedBox(height: 10),
          DouriAnimatedCounter(
            value: value,
            format: (v) => isQueueNumber
                ? (v == 0 ? '—' : '#$v')
                : v.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: DouriTextStyles.statLabel(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DouriPressable(
      onTap: onTap,
      child: DouriCard(
        padding: const EdgeInsets.symmetric(
          horizontal: DouriSpacing.md,
          vertical: DouriSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(DouriRadius.md),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: DouriSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

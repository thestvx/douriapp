import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
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
      backgroundColor: AppColors.primaryBackground,
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
              onAction: () => context.go('/barber/shop'),
            );
          }
          return IndexedStack(
            index: _index,
            children: [
              _DashboardBody(
                shop: shop,
                onGoToQueue: () => setState(() => _index = 1),
                onGoToBookings: () => setState(() => _index = 2),
              ),
              QueueManagementScreen(shopId: shop.id),
              BookingRequestsScreen(shopId: shop.id),
              BarberProfileScreen(onManageShop: () => context.go('/barber/shop')),
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
  });

  final int todayBookings;
  final int waiting;
  final int currentNumber; // 0 when nobody is being served
  final int completed;
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
  });

  final BarberShop shop;
  final VoidCallback onGoToQueue;
  final VoidCallback onGoToBookings;

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
    return _DayStats(
      todayBookings: bookings.where((Booking b) => _isToday(b.bookingDate)).length,
      waiting: entries.where((e) => e.isWaiting || e.isApproaching).length,
      currentNumber: current?.queueNumber ?? 0,
      completed: entries.where((e) => e.isCompleted).length,
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
      backgroundColor: AppColors.elevatedSurface,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DouriSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriEntrance(
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
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shop.shopName,
                          style: Theme.of(context).textTheme.headlineMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${now.day}/${now.month}/${now.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  DouriStatusBadge(open: shop.isOpen),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
            DouriEntrance(
              index: 1,
              child: DouriCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.isOpen ? l10n.shopOpen : l10n.shopClosed,
                        style: Theme.of(context).textTheme.titleMedium,
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
            const SizedBox(height: DouriSpacing.lg),
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
                return DouriEntrance(
                  index: 2,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: DouriSpacing.md,
                    crossAxisSpacing: DouriSpacing.md,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                        value: '${stats.todayBookings}',
                        label: l10n.todaysBookings,
                        icon: Icons.calendar_today_outlined,
                      ),
                      _StatCard(
                        value: '${stats.waiting}',
                        label: l10n.waitingCustomers,
                        icon: Icons.people_outline,
                      ),
                      _StatCard(
                        value: stats.currentNumber == 0 ? '—' : '#${stats.currentNumber}',
                        label: l10n.currentCustomer,
                        icon: Icons.person_outline,
                      ),
                      _StatCard(
                        value: '${stats.completed}',
                        label: l10n.completedToday,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriEntrance(
              index: 3,
              child: DouriSectionHeader(title: l10n.quickActions),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriEntrance(
              index: 4,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: DouriSpacing.md,
                crossAxisSpacing: DouriSpacing.md,
                childAspectRatio: 2.4,
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
                    onTap: () => context.go('/barber/shop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DouriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryAccent),
          const Spacer(),
          Text(value, style: DouriTextStyles.statValue(context)),
          const SizedBox(height: 2),
          Text(
            label,
            style: DouriTextStyles.statLabel(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DouriCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryAccent),
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
    );
  }
}

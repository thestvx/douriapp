import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../shared/models/booking.dart';
import '../../authentication/auth_providers.dart';
import '../bookings/my_bookings_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/customer_profile_screen.dart';
import 'shop_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = <Widget>[
      _HomeBody(
        onSearchSubmit: (query) {
          ref.read(exploreQueryProvider.notifier).state = query;
          setState(() => _index = 1);
        },
        onViewAll: () => setState(() => _index = 1),
      ),
      const ExploreScreen(),
      const MyBookingsScreen(),
      CustomerProfileScreen(onShowBookings: () => setState(() => _index = 2)),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: DouriBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          DouriNavItem(icon: Icons.home_outlined, label: l10n.home),
          DouriNavItem(icon: Icons.explore_outlined, label: l10n.explore),
          DouriNavItem(icon: Icons.calendar_today_outlined, label: l10n.bookings),
          DouriNavItem(icon: Icons.person_outline, label: l10n.profile),
        ],
      ),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({required this.onSearchSubmit, required this.onViewAll});
  final ValueChanged<String> onSearchSubmit;
  final VoidCallback onViewAll;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  final _searchController = TextEditingController();
  bool _openNowOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(shopsProvider);
    try {
      await ref.read(shopsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final displayName = (profile?.fullName ?? '').isNotEmpty
        ? profile!.fullName
        : l10n.appName;
    final shopsAsync = ref.watch(shopsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DouriSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DouriEntrance(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.hello},',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                          ),
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    DouriAvatar(
                      name: displayName,
                      imageUrl: profile?.avatarUrl,
                      radius: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DouriSpacing.lg),
              DouriEntrance(
                index: 1,
                child: DouriSearchField(
                  controller: _searchController,
                  hint: l10n.searchHint,
                  onSubmitted: widget.onSearchSubmit,
                ),
              ),
              const SizedBox(height: DouriSpacing.lg),
              _ActiveBookingSection(),
              shopsAsync.when(
                loading: () => const DouriSkeletonList(),
                error: (e, _) => DouriErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(shopsProvider),
                ),
                data: (shops) {
                  if (shops.isEmpty) {
                    return DouriEmptyState(
                      icon: Icons.store_outlined,
                      title: l10n.noShops,
                      message: l10n.noShopsMessage,
                    );
                  }
                  final visible = _openNowOnly
                      ? shops.where((s) => s.isOpen).toList()
                      : shops;
                  final featured = visible.where((s) => s.isOpen).toList();
                  final recommended =
                      visible.where((s) => !featured.contains(s)).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DouriEntrance(
                        index: 2,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text(l10n.openNow),
                              selected: _openNowOnly,
                              onSelected: (v) => setState(() => _openNowOnly = v),
                              selectedColor: AppColors.accentSoft,
                              checkmarkColor: AppColors.primaryAccent,
                            ),
                          ],
                        ),
                      ),
                      if (featured.isNotEmpty) ...[
                        const SizedBox(height: DouriSpacing.lg),
                        DouriEntrance(
                          index: 3,
                          child: DouriSectionHeader(
                            title: l10n.featuredShops,
                            actionLabel: l10n.viewAll,
                            onAction: widget.onViewAll,
                          ),
                        ),
                        const SizedBox(height: DouriSpacing.md),
                        SizedBox(
                          height: 250,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featured.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: DouriSpacing.md),
                            itemBuilder: (_, i) => DouriEntrance(
                              index: i,
                              child: SizedBox(
                                width: 260,
                                child: ShopRatingCard(shop: featured[i]),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: DouriSpacing.xl),
                      DouriEntrance(
                        index: 4,
                        child: DouriSectionHeader(
                          title: l10n.recommendedShops,
                          actionLabel: l10n.viewAll,
                          onAction: widget.onViewAll,
                        ),
                      ),
                      const SizedBox(height: DouriSpacing.md),
                      if (recommended.isEmpty && featured.isEmpty)
                        DouriEmptyState(
                          icon: Icons.store_outlined,
                          title: l10n.noShops,
                          message: l10n.noShopsMessage,
                        )
                      else
                        Column(
                          children: [
                            for (var i = 0; i < recommended.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                                child: DouriEntrance(
                                  index: i,
                                  child: ShopRatingCard(shop: recommended[i]),
                                ),
                              ),
                            if (recommended.isEmpty)
                              for (var i = 0; i < featured.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: DouriSpacing.md),
                                  child: DouriEntrance(
                                    index: i,
                                    child: ShopRatingCard(shop: featured[i]),
                                  ),
                                ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBookingSection extends ConsumerWidget {
  const _ActiveBookingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) return const SizedBox.shrink();
    final bookingsAsync = ref.watch(customerBookingsProvider(uid));
    return bookingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (bookings) {
        Booking? active;
        for (final b in bookings) {
          if (b.status == 'PENDING' || b.status == 'CONFIRMED') {
            active = b;
            break;
          }
        }
        if (active == null) return const SizedBox.shrink();
        final booking = active;
        final shop = ref.watch(shopByIdProvider(booking.barberShopId)).value;
        final d = booking.bookingDate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriEntrance(
              child: DouriSectionHeader(title: l10n.activeBooking),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriEntrance(
              index: 1,
              child: DouriBookingCard(
                title: shop?.shopName ?? booking.customerName,
                subtitle: booking.customerName,
                statusLabel: booking.status == 'PENDING'
                    ? l10n.bookingPending
                    : l10n.bookingConfirmed,
                statusColor: booking.status == 'PENDING'
                    ? AppColors.warning
                    : AppColors.success,
                queueNumber: booking.queueNumber,
                dateLabel: '${d.day}/${d.month}/${d.year}',
                timeLabel: booking.bookingTime,
                onTap: () {
                  if (booking.queueNumber != null) {
                    context.go('/queue/${booking.queueNumber}?bookingId=${booking.id}');
                  } else {
                    context.go('/booking-success/${booking.id}');
                  }
                },
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
          ],
        );
      },
    );
  }
}

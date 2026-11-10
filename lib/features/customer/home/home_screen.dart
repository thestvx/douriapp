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
import '../../../core/widgets/douri_motion.dart';
import '../../../core/widgets/douri_visual.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/booking.dart';
import '../../authentication/auth_providers.dart';
import '../bookings/my_bookings_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/customer_profile_screen.dart';
import 'shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

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

class _HomeBodyState extends ConsumerState<_HomeBody>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _openNowOnly = false;

  /// Entrance choreography (plays once per app session, ~750ms total):
  /// the greeting slides up, then the search field, then the sections fade
  /// in — a visible sequence, not a 40ms stagger. The hero gets its own
  /// scale/fade via [_HeroEntrance] when the shop data first arrives.
  /// Under reduced motion the controller jumps straight to its end value.
  static bool _entrancePlayed = false;
  late final AnimationController _entrance;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;
  late final Animation<double> _sectionsFade;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _greetingFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.05, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _greetingSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _searchFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _searchSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _sectionsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_entrancePlayed || DouriMotion.reduced(context)) {
        _entrance.value = 1.0;
      } else {
        _entrancePlayed = true;
        _entrance.forward();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
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
    // The hero lives at the very top of the screen (full-bleed), so the
    // featured shop is picked here from the already-watched provider
    // instead of inside the AnimatedSwitcher below.
    final shops = shopsAsync.value;
    final visible = shops == null
        ? null
        : (_openNowOnly ? shops.where((s) => s.isOpen).toList() : shops);
    final openShops =
        visible == null ? null : visible.where((s) => s.isOpen).toList();
    final heroShop =
        (openShops == null || openShops.isEmpty) ? null : openShops.first;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // 116dp bottom inset so the last card clears the floating pill nav.
          padding: const EdgeInsets.only(bottom: 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-bleed hero: the first open shop as a tall cover with
              // display type + Book CTA. While shops load, a shimmer block
              // in the same shape so the screen never looks blank. No hero
              // when there is no open shop — the greeting header below is
              // the graceful fallback.
              if (heroShop != null)
                _HeroEntrance(
                  child: _HomeHero(key: ValueKey(heroShop.id), shop: heroShop),
                )
              else if (shopsAsync.isLoading)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  child: const DouriShimmer(
                    width: double.infinity,
                    height: 340,
                    radius: 0,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DouriSpacing.page,
                  DouriSpacing.lg,
                  DouriSpacing.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _greetingFade,
                      child: SlideTransition(
                        position: _greetingSlide,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.hello},',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: context.douriColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryAccent,
                                  width: 1.5,
                                ),
                              ),
                              child: DouriAvatar(
                                name: displayName,
                                imageUrl: profile?.avatarUrl,
                                radius: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DouriSpacing.lg),
                    FadeTransition(
                      opacity: _searchFade,
                      child: SlideTransition(
                        position: _searchSlide,
                        child: DouriSearchField(
                          controller: _searchController,
                          hint: l10n.searchHint,
                          onSubmitted: widget.onSearchSubmit,
                        ),
                      ),
                    ),
                    const SizedBox(height: DouriSpacing.lg),
                    _ActiveBookingSection(),
                    FadeTransition(
                      opacity: _sectionsFade,
                      child: AnimatedSwitcher(
                        duration: DouriMotion.scaled(context, DouriDuration.normal),
                child: shopsAsync.when(
                  loading: () => const DouriSkeletonList(key: ValueKey('loading')),
                  error: (e, _) => DouriErrorState(
                    key: const ValueKey('error'),
                    message: e.toString(),
                    onRetry: () => ref.invalidate(shopsProvider),
                  ),
                  data: (shops) {
                    if (shops.isEmpty) {
                      return DouriEmptyState(
                        key: const ValueKey('empty'),
                        icon: Icons.store_outlined,
                        title: l10n.noShops,
                        message: l10n.noShopsMessage,
                      );
                    }
                    final visible = _openNowOnly
                        ? shops.where((s) => s.isOpen).toList()
                        : shops;
                    if (visible.isEmpty) {
                      // Shops exist, but the Open-now filter hides all of
                      // them — a different empty state than "no shops".
                      return DouriEmptyState(
                        key: const ValueKey('no-open'),
                        icon: Icons.store_outlined,
                        title: l10n.noOpenShops,
                        message: l10n.noOpenShopsMessage,
                        actionLabel: l10n.all,
                        onAction: () => setState(() => _openNowOnly = false),
                      );
                    }
                    final featured = visible.where((s) => s.isOpen).toList();
                    final recommended =
                        visible.where((s) => !s.isOpen).toList();
                    return Column(
                      key: const ValueKey('shops'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The featured shop now lives in the full-bleed
                        // hero at the top of the screen (see build), not
                        // as a banner inside this list.
                        DouriStagger(
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
                          DouriStagger(
                            index: 3,
                            child: DouriSectionHeader(
                              title: l10n.nearestToYou,
                              actionLabel: l10n.viewAll,
                              onAction: widget.onViewAll,
                            ),
                          ),
                          const SizedBox(height: DouriSpacing.md),
                          SizedBox(
                            height: 300,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: DouriSpacing.md),
                              itemBuilder: (_, i) => DouriStagger(
                                index: i,
                                child: SizedBox(
                                  width: 300,
                                  child: ShopRatingCard(
                                    key: ValueKey(featured[i].id),
                                    shop: featured[i],
                                    coverHeight: 190,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        // Recommended = the shops that are not open right
                        // now. When every visible shop is open the section
                        // is omitted: the carousel already shows them all,
                        // and re-rendering them here used to duplicate
                        // their Hero tags on this route.
                        if (recommended.isNotEmpty) ...[
                          const SizedBox(height: DouriSpacing.xl),
                          DouriStagger(
                            index: 4,
                            child: DouriSectionHeader(
                              title: l10n.recommendedShops,
                              actionLabel: l10n.viewAll,
                              onAction: widget.onViewAll,
                            ),
                          ),
                          const SizedBox(height: DouriSpacing.md),
                          Column(
                            children: [
                              for (var i = 0; i < recommended.length; i++)
                                Padding(
                                  key: ValueKey(recommended[i].id),
                                  padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                                  child: DouriStagger(
                                    index: i,
                                    child: ShopRatingCard(
                                      shop: recommended[i],
                                      coverHeight: 170,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
                    ),
            ],
          ),
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
            DouriStagger(
              child: DouriSectionHeader(title: l10n.activeBooking),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
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
                    context.push('/queue/${booking.queueNumber}?bookingId=${booking.id}');
                  } else {
                    context.push('/booking-success/${booking.id}');
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

/// Full-bleed hero for the first open shop: tall cover, display-size type,
/// rating + open badge on the image, lime Book Now CTA on the image. Built
/// only from real shop data (rating is null when there are no reviews).
/// No Hero tag here — the same shop also appears in the carousel below,
/// and two Heroes sharing a tag on one route would break the transition.
class _HomeHero extends ConsumerWidget {
  const _HomeHero({super.key, required this.shop});
  final BarberShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rating = ref.watch(shopRatingProvider(shop.id)).value;
    return DouriPromoBanner(
      name: shop.shopName,
      address: shop.address,
      coverImageUrl: shop.coverImageUrl,
      rating: rating?.rating,
      reviewCount: rating?.count,
      isOpen: shop.isOpen,
      eyebrow: l10n.featuredShops,
      height: 340,
      large: true,
      bleed: true,
      bookLabel: l10n.bookNow,
      onTap: () => context.push('/shop/${shop.id}'),
      onBook: () => context.push('/booking/${shop.id}'),
    );
  }
}

/// Hero entrance: scale 1.06 → 1 + fade over ~550ms when the hero first
/// mounts (i.e. when the shop data arrives). Renders the final state
/// immediately under reduced motion.
class _HeroEntrance extends StatelessWidget {
  const _HeroEntrance({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DouriMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 1.06 - 0.06 * t, child: child),
      ),
      child: child,
    );
  }
}

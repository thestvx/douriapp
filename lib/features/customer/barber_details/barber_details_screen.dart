import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../home/shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

class BarberDetailsScreen extends ConsumerStatefulWidget {
  const BarberDetailsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<BarberDetailsScreen> createState() => _BarberDetailsScreenState();
}

class _BarberDetailsScreenState extends ConsumerState<BarberDetailsScreen> {
  /// Locally selected service (visual state only). The booking screen owns
  /// the real service choice — this screen never passes the selection on,
  /// and the Book action still navigates to `/booking/:id` unchanged.
  String? _selectedServiceId;

  /// Back affordance for the loading/error/empty states, which have no
  /// hero back button — without it the user would be stuck on this route.
  Widget _stateWithBack({required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DouriSpacing.md),
            child: DouriIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopId = widget.shopId;
    final shopAsync = ref.watch(shopByIdProvider(shopId));

    return Scaffold(
      body: shopAsync.when(
        loading: () => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DouriSkeleton(height: 320, radius: 0),
              Padding(
                padding: const EdgeInsets.all(DouriSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DouriSkeleton(width: 180, height: 24, radius: 8),
                    const SizedBox(height: DouriSpacing.md),
                    const DouriSkeleton(width: 120, height: 14, radius: 8),
                    const SizedBox(height: DouriSpacing.xl),
                    const DouriSkeleton(height: 64, radius: 18),
                    const SizedBox(height: DouriSpacing.xl),
                    const DouriSkeleton(width: 110, height: 20, radius: 8),
                    const SizedBox(height: DouriSpacing.md),
                    const DouriSkeletonList(),
                  ],
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => _stateWithBack(
          child: DouriErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(shopByIdProvider(shopId)),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return _stateWithBack(
              child: DouriEmptyState(
                icon: Icons.store_outlined,
                title: l10n.noShops,
                message: l10n.noShopsMessage,
              ),
            );
          }
          final ratingAsync = ref.watch(shopRatingProvider(shopId));
          final servicesAsync = ref.watch(shopServicesProvider(shopId));
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Hero(
                            // Same tag as DouriShopCard ('shop-image-<id>')
                            // so the cover flies in from Home / Explore.
                            tag: 'shop-image-$shopId',
                            child: SizedBox(
                              height: 320,
                              width: double.infinity,
                              child: shop.coverImageUrl != null &&
                                      shop.coverImageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: shop.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const _CoverFallback(),
                                    )
                                  : const _CoverFallback(),
                            ),
                          ),
                          // Stylize hero: gradient + name/rating overlaid
                          // at the bottom of the cover.
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    context.douriColors.background.withValues(alpha: 0.35),
                                    context.douriColors.background.withValues(alpha: 0.95),
                                  ],
                                  stops: const [0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(DouriSpacing.md),
                              child: DouriIconButton(
                                icon: Icons.arrow_back_ios_new,
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: DouriSpacing.page,
                            right: DouriSpacing.page,
                            bottom: DouriSpacing.lg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        shop.shopName,
                                        style: Theme.of(context).textTheme.headlineMedium,
                                      ),
                                    ),
                                    DouriAnimatedBadge(
                                      child: DouriStatusBadge(
                                        key: ValueKey(shop.isOpen),
                                        open: shop.isOpen,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: DouriSpacing.sm),
                                ratingAsync.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                  data: (rating) => rating == null
                                      ? Text(
                                          l10n.noReviews,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: context.douriColors.textMuted,
                                              ),
                                        )
                                      : DouriRating(value: rating.rating, count: rating.count),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(DouriSpacing.page),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop identity: address, description and phone,
                            // grouped under one section header.
                            DouriStagger(
                              child: DouriSectionHeader(title: l10n.shopDetails),
                            ),
                            if (shop.address != null && shop.address!.isNotEmpty) ...[
                              SizedBox(height: DouriSpacing.md),
                              DouriStagger(
                                index: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: context.douriColors.textSecondary,
                                    ),
                                    const SizedBox(width: DouriSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        shop.address!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (shop.description != null && shop.description!.isNotEmpty) ...[
                              SizedBox(height: DouriSpacing.md),
                              DouriStagger(
                                index: 2,
                                child: Text(
                                  shop.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: context.douriColors.textSecondary,
                                      ),
                                ),
                              ),
                            ],
                            if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty) ...[
                              SizedBox(height: DouriSpacing.md),
                              DouriStagger(
                                index: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: context.douriColors.textSecondary,
                                    ),
                                    const SizedBox(width: DouriSpacing.sm),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          shop.phoneNumber!,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: DouriSpacing.xl),
                            DouriStagger(
                              index: 4,
                              child: DouriSectionHeader(title: l10n.currentQueue),
                            ),
                            const SizedBox(height: DouriSpacing.md),
                            DouriStagger(
                              index: 5,
                              child: FutureBuilder<Map<String, dynamic>?>(
                                future: ref
                                    .read(queueRepositoryProvider)
                                    .getTodayQueue(shop.id),
                                builder: (_, snapshot) {
                                  final queue = snapshot.data;
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const DouriSkeleton(height: 64, radius: 18);
                                  }
                                  if (queue == null) {
                                    return DouriCard(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.hourglass_empty,
                                            color: context.douriColors.textSecondary,
                                          ),
                                          const SizedBox(width: DouriSpacing.md),
                                          Expanded(
                                            child: Text(
                                              l10n.queueNotStarted,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final current = queue['current_queue_number'] as int?;
                                  return DouriCard(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.people_outline,
                                          color: DouriTextStyles.accent(context),
                                        ),
                                        const SizedBox(width: DouriSpacing.md),
                                        Expanded(
                                          child: Text(
                                            l10n.nowServing,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            current == null ? '—' : '#$current',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(color: DouriTextStyles.accent(context)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: DouriSpacing.xl),
                            DouriStagger(
                              index: 6,
                              child: DouriSectionHeader(title: l10n.services),
                            ),
                            const SizedBox(height: DouriSpacing.md),
                            servicesAsync.when(
                              loading: () => const DouriSkeletonList(),
                              error: (e, _) => DouriErrorState(
                                message: e.toString(),
                                onRetry: () => ref.invalidate(shopServicesProvider(shopId)),
                              ),
                              data: (services) {
                                if (services.isEmpty) {
                                  return DouriEmptyState(
                                    icon: Icons.content_cut,
                                    title: l10n.noServices,
                                    message: l10n.noServicesMessage,
                                  );
                                }
                                return Column(
                                  children: [
                                    for (var i = 0; i < services.length; i++)
                                      Padding(
                                        key: ValueKey(services[i].id),
                                        padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                                        child: DouriStagger(
                                          index: i,
                                          child: DouriServiceCard(
                                            name: services[i].serviceName,
                                            description: services[i].description,
                                            durationMinutes: services[i].durationMinutes,
                                            priceLabel: services[i].price == null
                                                ? null
                                                : services[i].price!.toStringAsFixed(0),
                                            // Selection is lime border +
                                            // filled check (never colour
                                            // alone) via DouriServiceCard.
                                            selected: _selectedServiceId == services[i].id,
                                            onTap: () => setState(() {
                                              _selectedServiceId =
                                                  _selectedServiceId == services[i].id
                                                      ? null
                                                      : services[i].id;
                                            }),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: DouriSpacing.xl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DouriSpacing.page,
                    DouriSpacing.sm,
                    DouriSpacing.page,
                    DouriSpacing.lg,
                  ),
                  child: DouriButton(
                    label: l10n.bookAppointment,
                    icon: Icons.calendar_today_outlined,
                    onPressed: () => context.push('/booking/${shop.id}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.douriColors.elevated,
      alignment: Alignment.center,
      child: Icon(Icons.content_cut, size: 64, color: DouriTextStyles.accent(context)),
    );
  }
}

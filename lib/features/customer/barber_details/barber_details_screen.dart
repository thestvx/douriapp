import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../home/shop_providers.dart';

class BarberDetailsScreen extends ConsumerWidget {
  const BarberDetailsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shopAsync = ref.watch(shopByIdProvider(shopId));

    return Scaffold(
      body: shopAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => DouriErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(shopByIdProvider(shopId)),
        ),
        data: (shop) {
          if (shop == null) {
            return DouriEmptyState(
              icon: Icons.store_outlined,
              title: l10n.noShops,
              message: l10n.noShopsMessage,
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
                            tag: 'shop-cover-$shopId',
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
                                    AppColors.primaryBackground.withValues(alpha: 0.35),
                                    AppColors.primaryBackground.withValues(alpha: 0.95),
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
                                    DouriStatusBadge(open: shop.isOpen),
                                  ],
                                ),
                                const SizedBox(height: DouriSpacing.sm),
                                ratingAsync.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                  data: (rating) => rating == null
                                      ? Text(
                                          l10n.noReviews,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.mutedText,
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
                            // Name + rating already sit on the hero above.
                            if (shop.address != null && shop.address!.isNotEmpty) ...[
                              const SizedBox(height: DouriSpacing.md),
                              DouriEntrance(
                                index: 2,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: AppColors.secondaryText,
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
                              const SizedBox(height: DouriSpacing.md),
                              DouriEntrance(
                                index: 3,
                                child: Text(
                                  shop.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                ),
                              ),
                            ],
                            if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty) ...[
                              const SizedBox(height: DouriSpacing.md),
                              DouriEntrance(
                                index: 4,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: DouriSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        shop.phoneNumber!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: DouriSpacing.xl),
                            DouriEntrance(
                              index: 5,
                              child: DouriSectionHeader(title: l10n.currentQueue),
                            ),
                            const SizedBox(height: DouriSpacing.md),
                            DouriEntrance(
                              index: 6,
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
                                          const Icon(
                                            Icons.hourglass_empty,
                                            color: AppColors.secondaryText,
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
                                          color: AppColors.primaryAccent,
                                        ),
                                        const SizedBox(width: DouriSpacing.md),
                                        Expanded(
                                          child: Text(
                                            l10n.nowServing,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                        Text(
                                          current == null ? '—' : '#$current',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(color: AppColors.primaryAccent),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: DouriSpacing.xl),
                            DouriEntrance(
                              index: 7,
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
                                        padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                                        child: DouriEntrance(
                                          index: i,
                                          child: DouriServiceCard(
                                            name: services[i].serviceName,
                                            description: services[i].description,
                                            durationMinutes: services[i].durationMinutes,
                                            priceLabel: services[i].price == null
                                                ? null
                                                : services[i].price!.toStringAsFixed(0),
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
                    onPressed: () => context.go('/booking/${shop.id}'),
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
      color: AppColors.elevatedSurface,
      alignment: Alignment.center,
      child: const Icon(Icons.content_cut, size: 64, color: AppColors.primaryAccent),
    );
  }
}

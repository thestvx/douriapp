import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../shared/models/barber_shop.dart';
import '../home/shop_providers.dart';

/// Search text shared with Home: submitting the home search field writes
/// here and switches to the Explore tab.
final exploreQueryProvider = StateProvider<String>((ref) => '');

enum _Sort { name, openFirst }

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.query});
  final String? query;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  bool _openNowOnly = false;
  _Sort _sort = _Sort.name;

  @override
  void initState() {
    super.initState();
    final q = widget.query;
    if (q != null && q.isNotEmpty) {
      _controller.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exploreQueryProvider.notifier).state = q;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(exploreQueryProvider);
    if (_controller.text != query) _controller.text = query;
    final shopsAsync = ref.watch(shopsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DouriSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriEntrance(
              child: Text(l10n.explore, style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: DouriSpacing.lg),
            DouriEntrance(
              index: 1,
              child: DouriSearchField(
                controller: _controller,
                hint: l10n.searchHint,
                onChanged: (v) => ref.read(exploreQueryProvider.notifier).state = v,
                onSubmitted: (v) => ref.read(exploreQueryProvider.notifier).state = v,
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriEntrance(
              index: 2,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.all),
                    selected: !_openNowOnly,
                    onSelected: (_) => setState(() => _openNowOnly = false),
                    selectedColor: AppColors.accentSoft,
                    checkmarkColor: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: DouriSpacing.sm),
                  FilterChip(
                    label: Text(l10n.openNow),
                    selected: _openNowOnly,
                    onSelected: (_) => setState(() => _openNowOnly = true),
                    selectedColor: AppColors.accentSoft,
                    checkmarkColor: AppColors.primaryAccent,
                  ),
                  const Spacer(),
                  PopupMenuButton<_Sort>(
                    icon: const Icon(Icons.sort, color: AppColors.secondaryText),
                    tooltip: l10n.sortBy,
                    onSelected: (s) => setState(() => _sort = s),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: _Sort.name, child: Text(l10n.name)),
                      PopupMenuItem(value: _Sort.openFirst, child: Text(l10n.openNow)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            Expanded(
              child: shopsAsync.when(
                loading: () => const DouriSkeletonList(),
                error: (e, _) => DouriErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(shopsProvider),
                ),
                data: (shops) {
                  final q = query.trim().toLowerCase();
                  var filtered = shops.where((s) {
                    if (_openNowOnly && !s.isOpen) return false;
                    if (q.isEmpty) return true;
                    return s.shopName.toLowerCase().contains(q) ||
                        (s.address ?? '').toLowerCase().contains(q) ||
                        (s.description ?? '').toLowerCase().contains(q);
                  }).toList();
                  switch (_sort) {
                    case _Sort.name:
                      filtered.sort((a, b) => a.shopName.compareTo(b.shopName));
                    case _Sort.openFirst:
                      filtered.sort((a, b) {
                        final open = (b.isOpen ? 1 : 0) - (a.isOpen ? 1 : 0);
                        return open != 0 ? open : a.shopName.compareTo(b.shopName);
                      });
                  }
                  if (filtered.isEmpty) {
                    return DouriEmptyState(
                      icon: Icons.search_off_outlined,
                      title: l10n.noResults,
                      message: l10n.noResultsMessage,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(shopsProvider);
                      try {
                        await ref.read(shopsProvider.future);
                      } catch (_) {}
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: DouriSpacing.md),
                      itemBuilder: (_, i) => DouriEntrance(
                        index: i,
                        child: ShopRatingCard(shop: filtered[i]),
                      ),
                    ),
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

/// A shop card with its real average rating (null when no reviews).
/// Shared with the Home tab.
class ShopRatingCard extends ConsumerWidget {
  const ShopRatingCard({super.key, required this.shop});
  final BarberShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(shopRatingProvider(shop.id)).valueOrNull;
    return DouriShopCard(
      shopId: shop.id,
      name: shop.shopName,
      address: shop.address,
      coverImageUrl: shop.coverImageUrl,
      logoUrl: shop.logoUrl,
      rating: rating?.rating,
      reviewCount: rating?.count,
      isOpen: shop.isOpen,
      onTap: () => context.go('/shop/${shop.id}'),
    );
  }
}

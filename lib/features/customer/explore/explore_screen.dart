import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/barber_shop.dart';
import '../home/shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

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
  final _searchFocus = FocusNode();
  bool _searchFocused = false;
  bool _openNowOnly = false;
  _Sort _sort = _Sort.name;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_handleFocusChange);
    final q = widget.query;
    if (q != null && q.isNotEmpty) {
      _controller.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exploreQueryProvider.notifier).state = q;
      });
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _searchFocused = _searchFocus.hasFocus);
  }

  void _cancelSearch() {
    _controller.clear();
    ref.read(exploreQueryProvider.notifier).state = '';
    _searchFocus.unfocus();
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_handleFocusChange);
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Stylize-style Filters bottom sheet. Draft values are applied only on
  /// "Apply Filter", so the sheet never changes the list by accident.
  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    var draftOpenNow = _openNowOnly;
    var draftSort = _sort;
    final applied = await showDouriSheet<bool>(
      context,
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filters, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: DouriSpacing.xl),
              Text(l10n.sortBy, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: DouriSpacing.md),
              RadioListTile<_Sort>(
                title: Text(l10n.name),
                value: _Sort.name,
                groupValue: draftSort,
                activeColor: AppColors.primaryAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheetState(() => draftSort = v ?? _Sort.name),
              ),
              RadioListTile<_Sort>(
                title: Text(l10n.openNow),
                value: _Sort.openFirst,
                groupValue: draftSort,
                activeColor: AppColors.primaryAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheetState(() => draftSort = v ?? _Sort.name),
              ),
              SwitchListTile(
                title: Text(l10n.openNow),
                value: draftOpenNow,
                activeThumbColor: AppColors.primaryAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheetState(() => draftOpenNow = v),
              ),
              const SizedBox(height: DouriSpacing.lg),
              DouriButton(
                label: l10n.applyFilters,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: DouriSpacing.sm),
              DouriButton(
                label: l10n.resetFilters,
                variant: DouriButtonVariant.ghost,
                onPressed: () {
                  draftOpenNow = false;
                  draftSort = _Sort.name;
                  setSheetState(() {});
                  Navigator.of(sheetContext).pop(true);
                },
              ),
            ],
          );
        },
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _openNowOnly = draftOpenNow;
        _sort = draftSort;
      });
    }
  }

  /// Animated filter chip (All / Open now — the existing criteria only).
  /// Selection is border + lime check + label weight, never colour alone.
  /// The check slot is always laid out (opacity-animated) so selecting a
  /// chip never shifts the label or the row.
  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.douriColors;
    final labelStyle = Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14, height: 1.2);
    return DouriPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DouriMotion.scaled(context, DouriDuration.normal),
        curve: DouriCurves.standard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : colors.elevated,
          borderRadius: BorderRadius.circular(DouriRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: DouriMotion.scaled(context, DouriDuration.fast),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: DouriTextStyles.accent(context)),
                  SizedBox(width: 6),
                ],
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: DouriMotion.scaled(context, DouriDuration.normal),
              curve: DouriCurves.standard,
              style: labelStyle.copyWith(
                color: selected ? DouriTextStyles.accent(context) : colors.text,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(exploreQueryProvider);
    if (_controller.text != query) _controller.text = query;
    final shopsAsync = ref.watch(shopsProvider);

    return SafeArea(
      child: Padding(
        // 116dp bottom inset so the last result clears the floating pill nav.
        padding: const EdgeInsets.fromLTRB(
          DouriSpacing.page,
          DouriSpacing.page,
          DouriSpacing.page,
          116,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriStagger(
              child: Text(l10n.explore, style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: DouriSpacing.lg),
            DouriStagger(
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    // Soft lime glow fades in while the field is focused;
                    // the field's own lime border comes from the theme.
                    child: AnimatedContainer(
                      duration: DouriMotion.scaled(context, DouriDuration.normal),
                      curve: DouriCurves.standard,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(
                              alpha: _searchFocused ? 0.16 : 0,
                            ),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: DouriSearchField(
                        controller: _controller,
                        focusNode: _searchFocus,
                        hint: l10n.searchHint,
                        onChanged: (v) => ref.read(exploreQueryProvider.notifier).state = v,
                        onSubmitted: (v) => ref.read(exploreQueryProvider.notifier).state = v,
                      ),
                    ),
                  ),
                  // Cancel slides in beside the field while it is focused;
                  // the field shrinks smoothly with it, never jumping.
                  AnimatedSwitcher(
                    duration: DouriMotion.scaled(context, DouriDuration.normal),
                    switchInCurve: DouriCurves.standard,
                    switchOutCurve: DouriCurves.standard,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    ),
                    child: _searchFocused
                        ? Padding(
                            key: const ValueKey('cancel'),
                            padding: const EdgeInsetsDirectional.only(start: DouriSpacing.sm),
                            child: TextButton(
                              onPressed: _cancelSearch,
                              child: Text(l10n.cancel),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 2,
              child: Row(
                children: [
                  _filterChip(
                    label: l10n.all,
                    selected: !_openNowOnly,
                    onTap: () => setState(() => _openNowOnly = false),
                  ),
                  const SizedBox(width: DouriSpacing.sm),
                  _filterChip(
                    label: l10n.openNow,
                    selected: _openNowOnly,
                    onTap: () => setState(() => _openNowOnly = true),
                  ),
                  const Spacer(),
                  DouriButton(
                    label: l10n.filters,
                    icon: Icons.tune,
                    variant: DouriButtonVariant.secondary,
                    expanded: false,
                    onPressed: _openFilters,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            Expanded(
              // Keyed states cross-fade (loading ↔ results ↔ empty) while
              // result changes reuse the same 'results' key, so rows update
              // in place with their stable ValueKeys instead of jumping.
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
                        key: const ValueKey('empty'),
                        icon: Icons.search_off_outlined,
                        title: l10n.noResults,
                        message: l10n.noResultsMessage,
                      );
                    }
                    return RefreshIndicator(
                      key: const ValueKey('results'),
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
                        itemBuilder: (_, i) => DouriStagger(
                          key: ValueKey(filtered[i].id),
                          index: i,
                          child: ShopRatingCard(shop: filtered[i]),
                        ),
                      ),
                    );
                  },
                ),
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
    final rating = ref.watch(shopRatingProvider(shop.id)).value;
    return DouriShopCard(
      shopId: shop.id,
      name: shop.shopName,
      address: shop.address,
      coverImageUrl: shop.coverImageUrl,
      logoUrl: shop.logoUrl,
      rating: rating?.rating,
      reviewCount: rating?.count,
      isOpen: shop.isOpen,
      onTap: () => context.push('/shop/${shop.id}'),
    );
  }
}

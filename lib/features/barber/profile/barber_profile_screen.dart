import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../core/widgets/douri_theme_picker.dart';
import '../../authentication/auth_providers.dart';
import '../dashboard/shop_provider.dart';
import '../../../core/theme/douri_colors.dart';

/// Barber profile tab: shop summary, owner account, language switch,
/// shop management entry point and logout.
class BarberProfileScreen extends ConsumerWidget {
  const BarberProfileScreen({super.key, required this.onManageShop});

  final VoidCallback onManageShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shopAsync = ref.watch(currentShopProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final locale = ref.watch(localeProvider);

    return Container(
      color: context.douriColors.background,
      child: SingleChildScrollView(
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
              index: 0,
              child: DouriSectionHeader(title: l10n.myShop),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 0,
              child: shopAsync.when(
                loading: () => const DouriSkeletonList(itemCount: 1),
                error: (_, __) => DouriCard(
                  child: Text(
                    l10n.actionFailed,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                data: (shop) {
                  if (shop == null) {
                    return DouriCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.noShopYet, style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: DouriSpacing.sm),
                          Text(
                            l10n.noShopMessage,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: context.douriColors.textSecondary),
                          ),
                          const SizedBox(height: DouriSpacing.md),
                          DouriButton(
                            label: l10n.createShop,
                            variant: DouriButtonVariant.secondary,
                            expanded: false,
                            onPressed: onManageShop,
                          ),
                        ],
                      ),
                    );
                  }
                  return DouriCard(
                    onTap: onManageShop,
                    child: Row(
                      children: [
                        DouriAvatar(name: shop.shopName, imageUrl: shop.logoUrl, radius: 28),
                        const SizedBox(width: DouriSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.shopName,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (shop.address != null && shop.address!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  shop.address!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: DouriSpacing.sm),
                              DouriAnimatedBadge(
                                child: DouriStatusBadge(
                                  key: ValueKey(shop.isOpen),
                                  open: shop.isOpen,
                                ),
                              ),
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
                  );
                },
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriStagger(
              index: 1,
              child: DouriSectionHeader(title: l10n.account),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 1,
              child: profileAsync.when(
                loading: () => const DouriSkeletonList(itemCount: 1),
                error: (_, __) => const SizedBox.shrink(),
                data: (profile) => DouriCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DouriAvatar(
                            name: profile?.fullName ?? '',
                            imageUrl: profile?.avatarUrl,
                            radius: 24,
                          ),
                          const SizedBox(width: DouriSpacing.md),
                          Expanded(
                            child: Text(
                              profile?.fullName ?? '—',
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DouriSpacing.md),
                      _ProfileRow(
                        label: l10n.phoneNumber,
                        value: profile?.phoneNumber ?? '—',
                        ltr: true,
                      ),
                      if (profile?.email != null && profile!.email!.isNotEmpty) ...[
                        const SizedBox(height: DouriSpacing.sm),
                        _ProfileRow(
                          label: l10n.email,
                          value: profile.email!,
                          ltr: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriStagger(
              index: 2,
              child: DouriSectionHeader(title: l10n.language),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 2,
              child: DouriCard(
                child: Row(
                  children: [
                    Expanded(
                      child: DouriButton(
                        label: 'العربية',
                        variant: locale.languageCode == 'ar'
                            ? DouriButtonVariant.primary
                            : DouriButtonVariant.secondary,
                        onPressed: () =>
                            ref.read(localeProvider.notifier).state = const Locale('ar'),
                      ),
                    ),
                    const SizedBox(width: DouriSpacing.sm),
                    Expanded(
                      child: DouriButton(
                        label: 'English',
                        variant: locale.languageCode == 'en'
                            ? DouriButtonVariant.primary
                            : DouriButtonVariant.secondary,
                        onPressed: () =>
                            ref.read(localeProvider.notifier).state = const Locale('en'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            // No section header here: DouriThemePicker renders its own
            // "Appearance" title inside the card.
            DouriStagger(
              index: 3,
              child: DouriCard(
                child: const DouriThemePicker(),
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriStagger(
              index: 4,
              child: DouriButton(
                label: l10n.shopManagement,
                icon: Icons.store_outlined,
                variant: DouriButtonVariant.secondary,
                onPressed: onManageShop,
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 5,
              child: DouriButton(
                label: l10n.logout,
                icon: Icons.logout_rounded,
                variant: DouriButtonVariant.danger,
                onPressed: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go('/auth');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    }
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value, this.ltr = false});

  final String label;
  final String value;

  /// Phone numbers and emails stay LTR even in the Arabic UI.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: Theme.of(context).textTheme.titleSmall,
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      children: [
        Expanded(
          child: Text(label, style: DouriTextStyles.statLabel(context)),
        ),
        const SizedBox(width: DouriSpacing.md),
        Expanded(
          child: ltr
              ? Directionality(
                  textDirection: TextDirection.ltr,
                  child: valueText,
                )
              : valueText,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../shared/models/profile.dart';
import '../../authentication/auth_providers.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key, required this.onShowBookings});
  final VoidCallback onShowBookings;

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _notifications = true;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, Profile profile) async {
    final l10n = AppLocalizations.of(context);
    _nameController.text = profile.fullName;
    final saved = await showDouriSheet<bool>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.editProfile, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DouriSpacing.lg),
          DouriTextField(
            controller: _nameController,
            label: l10n.fullName,
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: DouriSpacing.lg),
          DouriButton(
            label: l10n.save,
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(profileRepositoryProvider).upsertProfile(
                      Profile(
                        id: profile.id,
                        fullName: name,
                        phoneNumber: profile.phoneNumber,
                        email: profile.email,
                        appRole: profile.appRole,
                        avatarUrl: profile.avatarUrl,
                      ),
                    );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.actionFailed)),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
    if (saved == true) ref.invalidate(currentProfileProvider);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go('/auth');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final locale = ref.watch(localeProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DouriSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriEntrance(
              child: Text(l10n.profile, style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: DouriSpacing.xl),
            profileAsync.when(
              loading: () => const DouriSkeletonList(itemCount: 1),
              error: (e, _) => DouriErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
              data: (profile) {
                final name = (profile?.fullName ?? '').isNotEmpty
                    ? profile!.fullName
                    : l10n.hello;
                return DouriEntrance(
                  index: 1,
                  child: DouriCard(
                    child: Row(
                      children: [
                        DouriAvatar(name: name, imageUrl: profile?.avatarUrl, radius: 30),
                        const SizedBox(width: DouriSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              if (profile?.phoneNumber != null &&
                                  profile!.phoneNumber!.isNotEmpty)
                                Text(
                                  profile.phoneNumber!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (profile != null)
                          DouriIconButton(
                            icon: Icons.edit_outlined,
                            onPressed: () => _editName(context, ref, profile),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriEntrance(
              index: 2,
              child: DouriSectionHeader(title: l10n.preferences),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriEntrance(
              index: 3,
              child: DouriCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.notifications),
                      value: _notifications,
                      activeThumbColor: AppColors.primaryAccent,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _LanguageRow(
                      label: 'العربية',
                      selected: locale.languageCode == 'ar',
                      onTap: () => ref.read(localeProvider.notifier).state = const Locale('ar'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _LanguageRow(
                      label: 'English',
                      selected: locale.languageCode == 'en',
                      onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
            DouriEntrance(
              index: 4,
              child: DouriCard(
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode_outlined, color: AppColors.secondaryText),
                    const SizedBox(width: DouriSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.themeSettings,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.darkThemeOnly,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriEntrance(
              index: 5,
              child: DouriButton(
                label: l10n.bookingHistory,
                icon: Icons.history,
                variant: DouriButtonVariant.secondary,
                onPressed: widget.onShowBookings,
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriEntrance(
              index: 6,
              child: DouriSectionHeader(title: l10n.favoriteShops),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriEntrance(
              index: 7,
              child: DouriEmptyState(
                icon: Icons.favorite_border,
                title: l10n.favoriteShops,
                message: l10n.favoritesComingSoon,
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriEntrance(
              index: 8,
              child: DouriButton(
                label: l10n.logout,
                icon: Icons.logout,
                variant: DouriButtonVariant.danger,
                onPressed: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primaryAccent)
          : const Icon(Icons.circle_outlined, color: AppColors.mutedText),
      onTap: onTap,
    );
  }
}

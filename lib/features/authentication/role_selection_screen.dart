import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/repository_providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/douri_cards.dart';
import '../../core/widgets/douri_chrome.dart';
import '../../core/widgets/douri_fields.dart';
import '../../core/widgets/douri_motion.dart';
import '../../shared/models/profile.dart';
import '../../core/theme/douri_colors.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _choose(String role) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = Profile(
        id: widget.uid,
        fullName: _nameController.text.trim(),
        appRole: role,
      );
      await ref.read(profileRepositoryProvider).upsertProfile(profile);
      if (role == 'barber') {
        await ref.read(barberShopRepositoryProvider).upsertShop({
          'owner_id': widget.uid,
          'shop_name': 'My Barber Shop',
        });
      }
      if (!mounted) return;
      context.go(role == 'barber' ? '/barber' : '/customer');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.douriColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DouriSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: DouriSpacing.xxl),
                DouriStagger(
                  index: 0,
                  child: Text(l10n.roleTitle, style: Theme.of(context).textTheme.headlineMedium),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 1,
                  child: Text(
                    l10n.roleSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.douriColors.textSecondary),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxxl),
                DouriStagger(
                  index: 2,
                  child: DouriSectionHeader(title: l10n.fullName),
                ),
                const SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 3,
                  child: DouriTextField(
                    controller: _nameController,
                    hint: l10n.enterName,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return l10n.required;
                      return null;
                    },
                  ),
                ),
                SizedBox(height: DouriSpacing.xxxl),
                DouriStagger(
                  index: 4,
                  child: DouriSectionHeader(title: l10n.chooseAccountType),
                ),
                const SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 5,
                  child: DouriCard(
                    onTap: _saving ? null : () => _choose('customer'),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentSoft,
                          ),
                          child: Icon(Icons.person_outline, size: 28, color: AppColors.primaryAccent),
                        ),
                        SizedBox(width: DouriSpacing.lg),
                        Expanded(
                          child: Text(l10n.iamCustomer, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Icon(Icons.arrow_forward, color: context.douriColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: DouriSpacing.md),
                DouriStagger(
                  index: 6,
                  child: DouriCard(
                    onTap: _saving ? null : () => _choose('barber'),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentSoft,
                          ),
                          child: Icon(Icons.content_cut, size: 28, color: AppColors.primaryAccent),
                        ),
                        SizedBox(width: DouriSpacing.lg),
                        Expanded(
                          child: Text(l10n.iamBarber, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Icon(Icons.arrow_forward, color: context.douriColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                if (_saving) ...[
                  const SizedBox(height: DouriSpacing.xxl),
                  const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
                ],
                const SizedBox(height: DouriSpacing.lg),
                AnimatedSwitcher(
                  duration: DouriMotion.scaled(context, DouriDuration.normal),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _error == null
                      ? const SizedBox.shrink(key: ValueKey('no-error'))
                      : Container(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.all(DouriSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(DouriRadius.md),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: DouriSpacing.sm),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.danger,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: DouriSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

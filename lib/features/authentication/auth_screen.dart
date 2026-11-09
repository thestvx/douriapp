import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/repository_providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/douri_button.dart';
import '../../core/widgets/douri_feedback.dart';
import '../../core/widgets/douri_fields.dart';
import '../../core/widgets/douri_visual.dart';
import 'auth_providers.dart';
import '../../core/theme/douri_colors.dart';

/// Email + password login (Firebase Auth).
///
/// Phone-number registration is parked — see [AuthRepository]. New users
/// go to /signup (customer form or barber wizard); existing users sign in
/// here. After sign-in the profile decides the destination: no profile
/// yet → /role/:uid (legacy completion screen), barber → /barber,
/// customer → /customer.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cred = await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final uid = cred.user!.uid;
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(uid);
      try {
        await ref.read(notificationServiceProvider).initialize(uid);
      } catch (_) {}
      if (!mounted) return;
      if (profile == null) {
        context.go('/role/$uid');
      } else if (profile.appRole == 'barber') {
        context.go('/barber');
      } else {
        context.go('/customer');
      }
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
                DouriEntrance(
                  index: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DouriRadius.xl),
                    child: const DouriVisualPanel(
                      icon: Icons.content_cut,
                      height: 190,
                      iconSize: 64,
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriEntrance(
                  index: 1,
                  child: Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                  ),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriEntrance(
                  index: 3,
                  child: Text(
                    l10n.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriEntrance(
                  index: 4,
                  child: Text(
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriEntrance(
                  index: 5,
                  child: DouriTextField(
                    controller: _emailController,
                    label: l10n.email,
                    hint: l10n.enterEmail,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || !_isValidEmail(value.trim())) {
                        return l10n.invalidEmail;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: DouriSpacing.md),
                DouriEntrance(
                  index: 6,
                  child: DouriTextField(
                    controller: _passwordController,
                    label: l10n.password,
                    hint: l10n.enterPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: context.douriColors.textSecondary,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: DouriSpacing.lg),
                  DouriEntrance(
                    index: 7,
                    slide: false,
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: DouriSpacing.xxl),
                DouriEntrance(
                  index: 8,
                  child: DouriButton(
                    label: l10n.signIn,
                    loading: _saving,
                    onPressed: _saving ? null : _signIn,
                  ),
                ),
                const SizedBox(height: DouriSpacing.md),
                DouriEntrance(
                  index: 9,
                  child: Center(
                    child: GestureDetector(
                      onTap: _saving ? null : () => context.push('/signup'),
                      child: Text(
                        l10n.noAccount,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
                // TEMP (testing only): skip sign-in and browse as a guest.
                // No profile is created, so booking / queue actions that
                // need a signed-in user will not work. Remove before release.
                const SizedBox(height: DouriSpacing.sm),
                DouriButton(
                  label: l10n.skipLogin,
                  variant: DouriButtonVariant.ghost,
                  onPressed: () => context.go('/customer'),
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

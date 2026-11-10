import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/repository_providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/douri_button.dart';
import '../../core/widgets/douri_fields.dart';
import '../../core/widgets/douri_motion.dart';
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
  // Focus glow state: the field widget itself owns the lime focus
  // border (theme); the glow below is layered around it, so the field
  // widget is never rebuilt.
  bool _emailFocused = false;
  bool _passwordFocused = false;

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
                DouriStagger(
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
                DouriStagger(
                  index: 1,
                  child: Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DouriTextStyles.accent(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                  ),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 3,
                  child: Text(
                    l10n.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SizedBox(height: DouriSpacing.sm),
                DouriStagger(
                  index: 4,
                  child: Text(
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.douriColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.xxl),
                DouriStagger(
                  index: 5,
                  child: _FocusGlow(
                    focused: _emailFocused,
                    child: Focus(
                      onFocusChange: (v) => setState(() => _emailFocused = v),
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
                  ),
                ),
                SizedBox(height: DouriSpacing.md),
                DouriStagger(
                  index: 6,
                  child: _FocusGlow(
                    focused: _passwordFocused,
                    child: Focus(
                      onFocusChange: (v) => setState(() => _passwordFocused = v),
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
                  ),
                ),
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
                const SizedBox(height: DouriSpacing.xxl),
                DouriStagger(
                  index: 8,
                  child: DouriButton(
                    label: l10n.signIn,
                    loading: _saving,
                    onPressed: _saving ? null : _signIn,
                  ),
                ),
                const SizedBox(height: DouriSpacing.md),
                DouriStagger(
                  index: 9,
                  child: Center(
                    child: GestureDetector(
                      onTap: _saving ? null : () => context.push('/signup'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          l10n.noAccount,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DouriTextStyles.accent(context),
                                fontWeight: FontWeight.w600,
                              ),
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

/// Soft lime glow that fades in around a field while it has focus —
/// the same focus-glow language as the Explore search field. The field
/// widget itself is untouched; this only wraps it.
class _FocusGlow extends StatelessWidget {
  const _FocusGlow({required this.focused, required this.child});
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DouriMotion.scaled(context, DouriDuration.normal),
      curve: DouriCurves.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DouriRadius.md),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}

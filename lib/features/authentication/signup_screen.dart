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
import '../../core/widgets/douri_cards.dart';
import '../../core/widgets/douri_chrome.dart';
import '../../core/widgets/douri_fields.dart';
import '../../core/widgets/douri_motion.dart';
import '../../core/widgets/douri_visual.dart';
import '../../shared/models/profile.dart';
import 'auth_providers.dart';
import '../../core/theme/douri_colors.dart';

/// Account creation.
///
/// Step 1 is the account type: customer stays on this screen (one form:
/// first name, last name, email, password), barber goes to the multi-step
/// wizard at /signup/barber (salon, location, chairs, hours, owner).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCustomerForm = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  Future<void> _createCustomerAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cred = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final uid = cred.user!.uid;
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      await ref.read(profileRepositoryProvider).upsertProfile(
            Profile(
              id: uid,
              fullName: fullName,
              email: _emailController.text.trim(),
              appRole: 'customer',
            ),
          );
      try {
        await ref.read(notificationServiceProvider).initialize(uid);
      } catch (_) {}
      if (!mounted) return;
      context.go('/customer');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DouriStagger(
                index: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DouriRadius.xl),
                  child: const DouriVisualPanel(
                    icon: Icons.content_cut,
                    height: 150,
                    iconSize: 56,
                  ),
                ),
              ),
              SizedBox(height: DouriSpacing.xxl),
              DouriStagger(
                index: 1,
                child: Text(
                  _showCustomerForm ? l10n.signupAsCustomer : l10n.signupTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(height: DouriSpacing.sm),
              DouriStagger(
                index: 2,
                child: Text(
                  _showCustomerForm
                      ? l10n.customerSignupDesc
                      : l10n.chooseAccountType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.douriColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: DouriSpacing.xxl),
              DouriStagger(
                index: 3,
                child: _SignupStepIndicator(
                  step: _showCustomerForm ? 1 : 0,
                  labels: [l10n.stepAccountType, l10n.stepYourDetails],
                ),
              ),
              const SizedBox(height: DouriSpacing.xxl),
              if (!_showCustomerForm) ...[
                DouriStagger(
                  index: 4,
                  child: DouriCard(
                    onTap: () => setState(() => _showCustomerForm = true),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentSoft,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 28,
                            color: DouriTextStyles.accent(context),
                          ),
                        ),
                        const SizedBox(width: DouriSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.signupAsCustomer,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 2),
                              Text(
                                l10n.customerSignupDesc,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.douriColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: context.douriColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DouriSpacing.md),
                DouriStagger(
                  index: 5,
                  child: DouriCard(
                    onTap: () => context.push('/signup/barber'),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentSoft,
                          ),
                          child: Icon(
                            Icons.content_cut,
                            size: 28,
                            color: DouriTextStyles.accent(context),
                          ),
                        ),
                        const SizedBox(width: DouriSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.signupAsBarber,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 2),
                              Text(
                                l10n.barberSignupDesc,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.douriColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: context.douriColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DouriStagger(
                        index: 4,
                        child: DouriSectionHeader(title: l10n.fullName),
                      ),
                      const SizedBox(height: DouriSpacing.sm),
                      DouriStagger(
                        index: 5,
                        child: Row(
                          children: [
                            Expanded(
                              child: DouriTextField(
                                controller: _firstNameController,
                                label: l10n.firstName,
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: DouriSpacing.md),
                            Expanded(
                              child: DouriTextField(
                                controller: _lastNameController,
                                label: l10n.lastName,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DouriSpacing.md),
                      DouriStagger(
                        index: 5,
                        child: DouriSectionHeader(title: l10n.accountInfo),
                      ),
                      const SizedBox(height: DouriSpacing.sm),
                      DouriStagger(
                        index: 6,
                        child: DouriTextField(
                          controller: _emailController,
                          label: l10n.email,
                          hint: l10n.enterEmail,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                !_isValidEmail(value.trim())) {
                              return l10n.invalidEmail;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: DouriSpacing.md),
                      DouriStagger(
                        index: 6,
                        child: DouriTextField(
                          controller: _passwordController,
                          label: l10n.password,
                          hint: l10n.enterPassword,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                      SizedBox(height: DouriSpacing.md),
                      DouriStagger(
                        index: 7,
                        child: DouriTextField(
                          controller: _confirmController,
                          label: l10n.confirmPassword,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: context.douriColors.textSecondary,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return l10n.passwordsDontMatch;
                            }
                            return null;
                          },
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
                          label: l10n.signUp,
                          loading: _saving,
                          onPressed:
                              _saving ? null : _createCustomerAccount,
                        ),
                      ),
                      const SizedBox(height: DouriSpacing.sm),
                      DouriButton(
                        label: l10n.back,
                        variant: DouriButtonVariant.ghost,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _showCustomerForm = false),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DouriSpacing.md),
              Center(
                child: GestureDetector(
                  // Came here via push from login: pop back to it. If the
                  // screen was opened directly, fall back to /auth.
                  onTap: _saving
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/auth');
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      l10n.alreadyHaveAccount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DouriTextStyles.accent(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DouriSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered step indicator in the booking screen's language: lime
/// circles for reached steps, muted outline for upcoming, the circle
/// content cross-fading between number and check, and the `n / N — label`
/// line cross-fading on every step change.
class _SignupStepIndicator extends StatelessWidget {
  const _SignupStepIndicator({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              AnimatedContainer(
                duration: DouriDuration.normal,
                curve: DouriCurves.standard,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? AppColors.primaryAccent : context.douriColors.card,
                  border: Border.all(
                    color: i <= step ? AppColors.primaryAccent : context.douriColors.border,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: DouriDuration.fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: i < step
                      ? Icon(
                          Icons.check,
                          key: const ValueKey('done'),
                          size: 16,
                          color: context.douriColors.background,
                        )
                      : Text(
                          '${i + 1}',
                          key: const ValueKey('number'),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: i == step
                                    ? context.douriColors.background
                                    : context.douriColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                ),
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: DouriDuration.normal,
                    curve: DouriCurves.standard,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: i < step ? AppColors.primaryAccent : context.douriColors.border,
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: DouriSpacing.sm),
        AnimatedSwitcher(
          duration: DouriMotion.scaled(context, DouriDuration.normal),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Text(
            '${step + 1} / ${labels.length} — ${labels[step]}',
            key: ValueKey(step),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.douriColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

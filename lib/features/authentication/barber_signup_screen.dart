import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../shared/models/profile.dart';
import 'auth_providers.dart';
import '../../core/theme/douri_colors.dart';

/// Barber signup wizard (5 steps):
///   1. Email → 2. Password → 3. Salon + location → 4. Chairs + hours →
///   5. Owner name + phone (+213).
///
/// On submit it creates the Firebase account, the Supabase profile
/// (role `barber`) and the `barber_shops` row (address "district, city",
/// auto-detected lat/lng when available, chairs, working hours as JSON).
/// The `chairs_count` column comes from migration 003 — run it in the
/// Supabase SQL Editor before testing this flow.
class BarberSignupScreen extends ConsumerStatefulWidget {
  const BarberSignupScreen({super.key});

  @override
  ConsumerState<BarberSignupScreen> createState() =>
      _BarberSignupScreenState();
}

class _BarberSignupScreenState extends ConsumerState<BarberSignupScreen> {
  static const int _totalSteps = 5;

  int _step = 0;
  bool _forward = true;
  bool _saving = false;
  bool _locating = false;
  String? _error;
  String? _locationStatus;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  double? _latitude;
  double? _longitude;
  int _chairs = 3;
  final Set<String> _days = {'sat', 'sun', 'mon', 'tue', 'wed', 'thu'};
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _salonNameController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<(String, String)> _dayOptions(AppLocalizations l10n) => [
        ('sat', l10n.daySat),
        ('sun', l10n.daySun),
        ('mon', l10n.dayMon),
        ('tue', l10n.dayTue),
        ('wed', l10n.dayWed),
        ('thu', l10n.dayThu),
        ('fri', l10n.dayFri),
      ];

  String? _validateStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        if (!_isValidEmail(_emailController.text.trim())) {
          return l10n.invalidEmail;
        }
      case 1:
        if (_passwordController.text.length < 6) {
          return l10n.passwordTooShort;
        }
        if (_confirmController.text != _passwordController.text) {
          return l10n.passwordsDontMatch;
        }
      case 2:
        if (_salonNameController.text.trim().isEmpty ||
            _districtController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty) {
          return l10n.required;
        }
      case 3:
        if (_days.isEmpty) return l10n.required;
      case 4:
        if (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty) {
          return l10n.required;
        }
        if (_phoneController.text.trim().length != 9) {
          return l10n.invalidPhone;
        }
    }
    return null;
  }

  void _next(AppLocalizations l10n) {
    final error = _validateStep(l10n);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _forward = true;
      _error = null;
      _step++;
    });
  }

  /// Asks for location permission and stores the salon coordinates.
  /// The address fields stay manual — GPS only fills lat/lng.
  Future<void> _detectLocation(AppLocalizations l10n) async {
    setState(() {
      _locating = true;
      _locationStatus = null;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception(l10n.locationUnavailable);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(l10n.locationUnavailable);
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus =
            '${l10n.locationDetected} (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final error = _validateStep(l10n);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
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
      final ownerName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final phone = '+213${_phoneController.text.trim()}';
      await ref.read(profileRepositoryProvider).upsertProfile(
            Profile(
              id: uid,
              fullName: ownerName,
              phoneNumber: phone,
              email: _emailController.text.trim(),
              appRole: 'barber',
            ),
          );
      await ref.read(barberShopRepositoryProvider).upsertShop({
        'owner_id': uid,
        'shop_name': _salonNameController.text.trim(),
        'address':
            '${_districtController.text.trim()}، ${_cityController.text.trim()}',
        'latitude': _latitude,
        'longitude': _longitude,
        'phone_number': phone,
        'working_hours': {
          'days': _days.toList(),
          'open': _fmtTime(_openTime),
          'close': _fmtTime(_closeTime),
        },
        'chairs_count': _chairs,
      });
      try {
        await ref.read(notificationServiceProvider).initialize(uid);
      } catch (_) {}
      if (!mounted) return;
      context.go('/barber');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.accountInfo,
      l10n.password,
      l10n.salonInfo,
      l10n.workingHours,
      l10n.ownerInfo,
    ];
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
                  l10n.signupAsBarber,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(height: DouriSpacing.sm),
              // Numbered step indicator in the booking screen's language;
              // its `n / N — label` line replaces the old subtitle text.
              DouriStagger(
                index: 2,
                child: _WizardStepIndicator(step: _step, labels: titles),
              ),
              const SizedBox(height: DouriSpacing.xxl),
              AnimatedSwitcher(
                duration: DouriMotion.scaled(context, DouriDuration.normal),
                switchInCurve: DouriCurves.standard,
                switchOutCurve: DouriCurves.standard,
                transitionBuilder: (child, animation) {
                  if (DouriMotion.reduced(context)) {
                    return FadeTransition(opacity: animation, child: child);
                  }
                  // Forward enters from the end side (right in LTR,
                  // left in RTL); back reverses — same as the booking flow.
                  final rtl =
                      Directionality.of(context) == TextDirection.rtl;
                  final dx = (_forward ? 0.12 : -0.12) * (rtl ? -1 : 1);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(dx, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(_step),
                  child: _buildStep(l10n),
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
              if (_step < _totalSteps - 1)
                DouriButton(
                  label: l10n.next,
                  onPressed: () => _next(l10n),
                )
              else
                DouriButton(
                  label: l10n.createBarberAccount,
                  loading: _saving,
                  onPressed: _saving ? null : _finish,
                ),
              if (_step > 0) ...[
                const SizedBox(height: DouriSpacing.sm),
                DouriButton(
                  label: l10n.back,
                  variant: DouriButtonVariant.ghost,
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _forward = false;
                            _error = null;
                            _step--;
                          }),
                ),
              ],
              const SizedBox(height: DouriSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return DouriStagger(
          child: DouriTextField(
            controller: _emailController,
            label: l10n.email,
            hint: l10n.enterEmail,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        );
      case 1:
        return Column(
          children: [
            DouriStagger(
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
              ),
            ),
            SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 1,
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
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            DouriStagger(
              child: DouriTextField(
                controller: _salonNameController,
                label: l10n.salonName,
                prefixIcon: Icons.store_outlined,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    child: DouriTextField(
                      controller: _districtController,
                      label: l10n.district,
                      prefixIcon: Icons.location_on_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: DouriSpacing.md),
                  Expanded(
                    child: DouriTextField(
                      controller: _cityController,
                      label: l10n.city,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 2,
              child: DouriButton(
                label: l10n.detectLocation,
                icon: Icons.my_location,
                variant: DouriButtonVariant.secondary,
                loading: _locating,
                onPressed: _locating ? null : () => _detectLocation(l10n),
              ),
            ),
            if (_locationStatus != null) ...[
              const SizedBox(height: DouriSpacing.sm),
              DouriStagger(
                index: 3,
                child: Text(
                  _locationStatus!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DouriTextStyles.accent(context),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriStagger(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chairs, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: DouriSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: DouriTextStyles.accent(context),
                          iconSize: 32,
                          onPressed: _chairs > 1
                              ? () => setState(() => _chairs--)
                              : null,
                        ),
                      ),
                      const SizedBox(width: DouriSpacing.md),
                      AnimatedSwitcher(
                        duration: DouriMotion.scaled(context, DouriDuration.fast),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.85, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          '$_chairs',
                          key: ValueKey(_chairs),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: DouriSpacing.md),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: DouriTextStyles.accent(context),
                          iconSize: 32,
                          onPressed: _chairs < 20
                              ? () => setState(() => _chairs++)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriStagger(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.workingDays,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: DouriSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayOptions(l10n).map((day) {
                      final selected = _days.contains(day.$1);
                      return _WizardDayPill(
                        label: day.$2,
                        selected: selected,
                        onTap: () => setState(() {
                          if (selected) {
                            _days.remove(day.$1);
                          } else {
                            _days.add(day.$1);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.xl),
            DouriStagger(
              index: 2,
              child: Row(
                children: [
                  Expanded(
                    child: DouriButton(
                      label: '${l10n.openTime}: ${_openTime.format(context)}',
                      variant: DouriButtonVariant.secondary,
                      onPressed: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: DouriSpacing.md),
                  Expanded(
                    child: DouriButton(
                      label: '${l10n.closeTime}: ${_closeTime.format(context)}',
                      variant: DouriButtonVariant.secondary,
                      onPressed: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            DouriStagger(
              child: Row(
                children: [
                  Expanded(
                    child: DouriTextField(
                      controller: _firstNameController,
                      label: l10n.firstName,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: DouriSpacing.md),
                  Expanded(
                    child: DouriTextField(
                      controller: _lastNameController,
                      label: l10n.lastName,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 1,
              child: DouriPhoneField(
                controller: _phoneController,
                countryCode: '+213',
                hint: l10n.phoneHint,
              ),
            ),
          ],
        );
    }
  }
}

/// Numbered step indicator in the booking screen's language: lime
/// circles for reached steps, muted outline for upcoming, the circle
/// content cross-fading between number and check, and the `n / N — label`
/// line cross-fading on every step change.
class _WizardStepIndicator extends StatelessWidget {
  const _WizardStepIndicator({required this.step, required this.labels});
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

/// Animated working-day pill, same language as the booking day pills:
/// selected = lime-soft fill + lime border + check icon + bold lime
/// label (border + icon + weight, never colour alone). The check slot is
/// always laid out and only its opacity animates, so toggling a day
/// never shifts the label or the row.
class _WizardDayPill extends StatelessWidget {
  const _WizardDayPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DouriPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DouriDuration.normal,
        curve: DouriCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: DouriSpacing.md,
          vertical: DouriSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : context.douriColors.card,
          borderRadius: BorderRadius.circular(DouriRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : context.douriColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: DouriDuration.fast,
              child: Icon(Icons.check, size: 16, color: DouriTextStyles.accent(context)),
            ),
            const SizedBox(width: DouriSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? DouriTextStyles.accent(context)
                        : context.douriColors.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

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
import 'auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  String? _verificationId;
  String _otpCode = '';
  bool _sending = false;
  String? _error;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  int _otpResetKey = 0; // bumped on resend/back so DouriOtpField rebuilds empty

  bool get _isOtpStep => _verificationId != null;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    final digits = _phoneController.text.trim();
    if (digits.length != 9) {
      setState(() => _error = AppLocalizations.of(context).invalidPhone);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    await repo.sendOtp(
      phoneNumber: '+213$digits',
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _sending = false;
          _otpCode = '';
          _otpResetKey++;
        });
        _startResendCountdown();
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _error = e.message;
          _sending = false;
        });
      },
    );
  }

  Future<void> _verify() async {
    if (_verificationId == null) return;
    if (_otpCode.length != 6) {
      setState(() => _error = AppLocalizations.of(context).invalidOtp);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final cred = await ref.read(authRepositoryProvider).verifyOtp(
            verificationId: _verificationId!,
            smsCode: _otpCode,
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
      if (mounted) setState(() => _sending = false);
    }
  }

  void _backToPhone() {
    _resendTimer?.cancel();
    setState(() {
      _verificationId = null;
      _otpCode = '';
      _otpResetKey++;
      _resendSeconds = 0;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DouriSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: DouriSpacing.xxxl),
              DouriEntrance(
                index: 0,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.elevatedSurface,
                    border: Border.all(color: AppColors.primaryAccent, width: 1.5),
                  ),
                  child: const Icon(Icons.content_cut, size: 44, color: AppColors.primaryAccent),
                ),
              ),
              const SizedBox(height: DouriSpacing.xl),
              DouriEntrance(
                index: 1,
                child: Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                ),
              ),
              const SizedBox(height: DouriSpacing.sm),
              DouriEntrance(
                index: 2,
                child: Text(
                  l10n.slogan,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryAccent),
                ),
              ),
              const SizedBox(height: DouriSpacing.xxxl),
              DouriEntrance(
                index: 3,
                child: Text(
                  _isOtpStep ? l10n.enterOtp : l10n.loginTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DouriSpacing.sm),
              DouriEntrance(
                index: 4,
                child: Text(
                  _isOtpStep
                      ? '${l10n.otpSentTo} +213 ${_phoneController.text.trim()}'
                      : l10n.loginSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DouriSpacing.xxl),
              if (!_isOtpStep) ...[
                DouriEntrance(
                  index: 5,
                  child: DouriPhoneField(
                    controller: _phoneController,
                    countryCode: '+213',
                    hint: l10n.phoneHint,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                ),
              ] else ...[
                DouriEntrance(
                  index: 5,
                  child: DouriOtpField(
                    key: ValueKey(_otpResetKey),
                    onCompleted: (code) {
                      setState(() {
                        _otpCode = code;
                        _error = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: DouriSpacing.xl),
                DouriEntrance(
                  index: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.didntGetCode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                      ),
                      const SizedBox(width: DouriSpacing.sm),
                      if (_resendSeconds > 0)
                        Text(
                          '${l10n.resendIn} $_resendSeconds',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                        )
                      else
                        GestureDetector(
                          onTap: _sending ? null : _sendOtp,
                          child: Text(
                            l10n.resendCode,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: DouriSpacing.lg),
                DouriEntrance(
                  index: 6,
                  slide: false,
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: DouriSpacing.xxl),
              DouriEntrance(
                index: 7,
                child: DouriButton(
                  label: _isOtpStep ? l10n.verify : l10n.sendCode,
                  loading: _sending,
                  onPressed: _sending ? null : (_isOtpStep ? _verify : _sendOtp),
                ),
              ),
              if (_isOtpStep) ...[
                const SizedBox(height: DouriSpacing.sm),
                DouriButton(
                  label: l10n.back,
                  variant: DouriButtonVariant.ghost,
                  onPressed: _sending ? null : _backToPhone,
                ),
              ] else ...[
                // TEMP (testing only): skip sign-in and browse as a guest.
                // No profile is created, so booking / queue actions that
                // need a signed-in user will not work. Remove before release.
                const SizedBox(height: DouriSpacing.sm),
                DouriButton(
                  label: l10n.skipLogin,
                  variant: DouriButtonVariant.ghost,
                  onPressed: () => context.go('/customer'),
                ),
              ],
              const SizedBox(height: DouriSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

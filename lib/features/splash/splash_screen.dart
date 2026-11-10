import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/app_prefs.dart';
import '../../core/services/repository_providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/douri_colors.dart';
import '../authentication/auth_providers.dart';

/// Premium launch experience: logo reveal with a lime ring pulse, then
/// the session decides the destination — a signed-in user goes straight
/// to their home (customer/barber), a signed-in user without a profile
/// goes to role selection, and a signed-out user goes to onboarding
/// (first launch) or login. The session is Firebase Auth's, which
/// persists across restarts; the splash only reads it, never resets it.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Keep the brand moment, but never longer than the auth check needs.
    final stopwatch = Stopwatch()..start();
    final user = await ref
        .read(authRepositoryProvider)
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => null)
        .catchError((_) => null);
    final remaining = 1900 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    if (!mounted) return;
    if (user == null) {
      final seen = await AppPrefs.loadOnboardingSeen();
      if (!mounted) return;
      context.go(seen ? '/auth' : '/onboarding');
      return;
    }
    final profile = await ref.read(profileRepositoryProvider).getProfile(user.uid);
    if (!mounted) return;
    if (profile == null) {
      context.go('/role/${user.uid}');
    } else if (profile.appRole == 'barber') {
      context.go('/barber');
    } else {
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Under reduced motion every element renders in its final state
    // immediately — no entrance animation at all.
    final reduced = DouriMotion.reduced(context);

    final logo = Stack(
      alignment: Alignment.center,
      children: [
        // Lime ring around the mark (the pulse the doc comment promised).
        Container(
          width: 136,
          height: 136,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: context.douriColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: context.douriColors.border),
          ),
          child: Icon(Icons.content_cut, size: 56, color: DouriTextStyles.accent(context)),
        ),
      ],
    );
    final logoChild = reduced
        ? logo
        : logo
            .animate()
            .scale(duration: DouriDuration.slow, curve: DouriCurves.emphasis, begin: const Offset(0.7, 0.7))
            .fadeIn(duration: DouriDuration.slow);

    final wordmark = Text('DOURI', style: Theme.of(context).textTheme.displayMedium?.copyWith(letterSpacing: 6));
    final wordmarkChild = reduced
        ? wordmark
        : wordmark
            .animate(delay: 250.ms)
            .fadeIn(duration: DouriDuration.slow)
            .slideY(begin: 0.2, end: 0, duration: DouriDuration.slow, curve: DouriCurves.entrance);

    final tagline = Text(l10n.splashTagline, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.douriColors.textSecondary));
    final taglineChild = reduced
        ? tagline
        : tagline.animate(delay: 450.ms).fadeIn(duration: DouriDuration.slow);

    final progress = SizedBox(
      width: 120,
      child: LinearProgressIndicator(
        backgroundColor: context.douriColors.elevated,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        minHeight: 3,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    final progressChild = reduced ? progress : progress.animate(delay: 500.ms).fadeIn();

    return Scaffold(
      backgroundColor: context.douriColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logoChild,
            const SizedBox(height: DouriSpacing.xxl),
            wordmarkChild,
            const SizedBox(height: DouriSpacing.sm),
            taglineChild,
            const SizedBox(height: DouriSpacing.xxxl),
            progressChild,
          ],
        ),
      ),
    );
  }
}

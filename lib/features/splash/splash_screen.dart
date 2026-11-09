import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_tokens.dart';

/// Premium launch experience: logo reveal with a lime ring pulse, then a
/// smooth transition to onboarding. No generic spinner as the hero.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.content_cut, size: 56, color: AppColors.primaryAccent),
            )
                .animate()
                .scale(duration: DouriDuration.slow, curve: DouriCurves.emphasis, begin: const Offset(0.7, 0.7))
                .fadeIn(duration: DouriDuration.slow),
            const SizedBox(height: DouriSpacing.xxl),
            Text('DOURI', style: Theme.of(context).textTheme.displayMedium?.copyWith(letterSpacing: 6))
                .animate(delay: 250.ms)
                .fadeIn(duration: DouriDuration.slow)
                .slideY(begin: 0.2, end: 0, duration: DouriDuration.slow, curve: DouriCurves.entrance),
            const SizedBox(height: DouriSpacing.sm),
            Text(l10n.splashTagline, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText))
                .animate(delay: 450.ms)
                .fadeIn(duration: DouriDuration.slow),
            const SizedBox(height: DouriSpacing.xxxl),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.elevatedSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

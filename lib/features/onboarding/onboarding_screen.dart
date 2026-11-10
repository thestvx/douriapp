import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/app_prefs.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/douri_motion.dart';
import '../../core/widgets/douri_visual.dart';
import '../../core/theme/douri_colors.dart';

/// Stylize-style onboarding (DOURI skin): full-bleed visual panel on top,
/// bold title + subtitle at the bottom, animated dots and a round lime
/// arrow CTA. No photos are copied from the Stylize template — the visual
/// is a dark gradient panel with lime iconography (real shop photos do not
/// exist in this repo).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 2) {
      _finish();
    } else {
      _pageController.animateToPage(
        _page + 1,
        duration: DouriDuration.normal,
        curve: DouriCurves.standard,
      );
    }
  }

  Future<void> _finish() async {
    await AppPrefs.saveOnboardingSeen();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    final slides = <({IconData icon, String title, String desc})>[
      (icon: Icons.storefront, title: l10n.onboarding1Title, desc: l10n.onboarding1Desc),
      (icon: Icons.calendar_month, title: l10n.onboarding2Title, desc: l10n.onboarding2Desc),
      (icon: Icons.confirmation_number_outlined, title: l10n.onboarding3Title, desc: l10n.onboarding3Desc),
    ];

    return Scaffold(
      backgroundColor: context.douriColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: DouriVisualPanel(icon: slide.icon),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DouriSpacing.page,
                        DouriSpacing.xl,
                        DouriSpacing.page,
                        DouriSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DouriStagger(
                            key: ValueKey('title-$index'),
                            child: Text(
                              slide.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          SizedBox(height: DouriSpacing.md),
                          DouriStagger(
                            key: ValueKey('desc-$index'),
                            index: 1,
                            child: Text(
                              slide.desc,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.douriColors.textSecondary,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              _LanguageChip(
                                label: 'العربية',
                                selected: locale.languageCode == 'ar',
                                onTap: () => ref.read(localeProvider.notifier).state = const Locale('ar'),
                              ),
                              const SizedBox(width: DouriSpacing.sm),
                              _LanguageChip(
                                label: 'English',
                                selected: locale.languageCode == 'en',
                                onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
                              ),
                            ],
                          ),
                          const SizedBox(height: DouriSpacing.xl),
                          Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(slides.length, (i) {
                                  final active = i == _page;
                                  return AnimatedContainer(
                                    duration: DouriDuration.normal,
                                    curve: DouriCurves.standard,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: active ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: active ? AppColors.primaryAccent : context.douriColors.border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                              const Spacer(),
                              DouriRoundArrowButton(onPressed: _next),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DouriSpacing.page,
                vertical: DouriSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                  ),
                  if (_page < 2)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.skip,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: context.douriColors.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DouriRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DouriRadius.pill),
        child: AnimatedContainer(
          duration: DouriDuration.normal,
          curve: DouriCurves.standard,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(DouriRadius.pill),
            border: Border.all(color: selected ? AppColors.primaryAccent : context.douriColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primaryAccent : context.douriColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

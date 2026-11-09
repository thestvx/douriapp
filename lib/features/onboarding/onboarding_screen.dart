import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/douri_button.dart';
import '../../core/widgets/douri_feedback.dart';

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

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: DouriDuration.normal,
      curve: DouriCurves.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isLast = _page == 2;

    final slides = <({IconData icon, String title, String desc})>[
      (icon: Icons.storefront, title: l10n.onboarding1Title, desc: l10n.onboarding1Desc),
      (icon: Icons.calendar_month, title: l10n.onboarding2Title, desc: l10n.onboarding2Desc),
      (icon: Icons.confirmation_number_outlined, title: l10n.onboarding3Title, desc: l10n.onboarding3Desc),
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DouriSpacing.page),
          child: Column(
            children: [
              const SizedBox(height: DouriSpacing.md),
              Row(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DouriSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DouriEntrance(
                            index: 0,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.elevatedSurface,
                                border: Border.all(color: AppColors.primaryAccent, width: 1.5),
                              ),
                              child: Icon(slide.icon, size: 72, color: AppColors.primaryAccent),
                            ),
                          ),
                          const SizedBox(height: DouriSpacing.xxxl),
                          DouriEntrance(
                            index: 1,
                            child: Text(
                              slide.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: DouriSpacing.lg),
                          DouriEntrance(
                            index: 2,
                            child: Text(
                              slide.desc,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              DouriEntrance(
                index: 0,
                slide: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (index) {
                    final active = index == _page;
                    return AnimatedContainer(
                      duration: DouriDuration.normal,
                      curve: DouriCurves.standard,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryAccent : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: DouriSpacing.xl),
              DouriButton(
                label: isLast ? l10n.getStarted : l10n.next,
                onPressed: () {
                  if (isLast) {
                    context.go('/auth');
                  } else {
                    _goToPage(_page + 1);
                  }
                },
              ),
              const SizedBox(height: DouriSpacing.sm),
              if (!isLast)
                DouriButton(
                  label: l10n.skip,
                  variant: DouriButtonVariant.ghost,
                  onPressed: () => context.go('/auth'),
                )
              else
                const SizedBox(height: 48),
              const SizedBox(height: DouriSpacing.lg),
            ],
          ),
        ),
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
      color: selected ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(DouriRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DouriRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DouriRadius.pill),
            border: Border.all(color: selected ? AppColors.primaryAccent : AppColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primaryAccent : AppColors.secondaryText,
                ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_controller.dart';

/// Appearance picker (System / Dark / Light) used on the customer and
/// barber profile screens. The choice applies immediately and is saved
/// by [setThemeMode].
class DouriThemePicker extends ConsumerWidget {
  const DouriThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final options = <(DouriThemeMode, String, IconData)>[
      (DouriThemeMode.system, l10n.themeSystem, Icons.brightness_auto_outlined),
      (DouriThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
      (DouriThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.themeSettings, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: DouriSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              Expanded(
                child: _ModeButton(
                  label: options[i].$2,
                  icon: options[i].$3,
                  selected: mode == options[i].$1,
                  onTap: () => setThemeMode(ref, options[i].$1),
                ),
              ),
              if (i < options.length - 1) const SizedBox(width: DouriSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryAccent : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primaryAccent
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.primaryAccent : null,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

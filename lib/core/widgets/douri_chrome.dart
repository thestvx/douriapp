import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/douri_colors.dart';

/// Open/Closed badge. Uses lime for open, muted for closed.
class DouriStatusBadge extends StatelessWidget {
  const DouriStatusBadge({super.key, required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: open ? AppColors.accentSoft : context.douriColors.overlaySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: open ? AppColors.primaryAccent : context.douriColors.textMuted,
            ),
          ),
          SizedBox(width: 5),
          Text(
            open ? l10n.open : l10n.closed,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: open ? AppColors.primaryAccent : context.douriColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Star rating. Only rendered when a real rating exists (callers must not
/// pass an invented value).
class DouriRating extends StatelessWidget {
  const DouriRating({super.key, required this.value, this.count});
  final double value;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
        SizedBox(width: 3),
        Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.labelMedium),
        if (count != null) ...[
          SizedBox(width: 3),
          Text('($count)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.douriColors.textMuted)),
        ],
      ],
    );
  }
}

/// Avatar with initials fallback. [imageUrl] may be null.
class DouriAvatar extends StatelessWidget {
  const DouriAvatar({super.key, required this.name, this.imageUrl, this.radius = 20});
  final String name;
  final String? imageUrl;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: context.douriColors.elevated, shape: BoxShape.circle),
        child: Text(_initials, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryAccent)),
      );
}

/// Section header with optional trailing action.
class DouriSectionHeader extends StatelessWidget {
  const DouriSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Standard app bar: no center title, lime back chevron handled by Flutter.
class DouriAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DouriAppBar({super.key, required this.title, this.actions, this.centerTitle = false});
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions, centerTitle: centerTitle);
  }
}

/// Custom premium bottom navigation: floating dark pill with a sliding
/// lime pill behind the active item. Haptic feedback on tap.
///
/// The sliding pill is direction-aware: [AlignmentDirectional] keeps the
/// first item at the start edge in both LTR and RTL. The active icon
/// scales (transform only, no layout shift) and the label gains weight.
class DouriBottomNav extends StatelessWidget {
  const DouriBottomNav({super.key, required this.currentIndex, required this.onTap, required this.items});
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DouriNavItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.douriColors;
    final labelStyle = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11, height: 1.2);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            children: [
              // Sliding lime pill behind the active item.
              if (items.isNotEmpty)
                AnimatedAlign(
                  alignment: _pillAlignment(currentIndex, items.length),
                  duration: DouriDuration.normal,
                  curve: DouriCurves.standard,
                  child: FractionallySizedBox(
                    widthFactor: 1 / items.length,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: List.generate(items.length, (i) {
                  final active = i == currentIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      borderRadius: BorderRadius.circular(34),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: active ? 1.15 : 1.0,
                            duration: DouriDuration.fast,
                            curve: DouriCurves.standard,
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: active ? AppColors.primaryAccent : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: DouriDuration.fast,
                            curve: DouriCurves.standard,
                            style: labelStyle.copyWith(
                              color: active ? AppColors.primaryAccent : colors.textSecondary,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                            child: Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Direction-aware pill alignment: -1 is the start edge (left in LTR,
/// right in RTL), +1 the end edge. [index] is clamped to a valid item.
/// Pure function of its arguments — uses no [BuildContext].
AlignmentGeometry _pillAlignment(int index, int count) {
  if (count <= 1) return AlignmentDirectional.center;
  final clamped = index.clamp(0, count - 1);
  final x = -1 + (2 * clamped / (count - 1));
  return AlignmentDirectional(x, 0);
}

class DouriNavItem {
  const DouriNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

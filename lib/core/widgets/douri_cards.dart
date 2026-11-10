import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'douri_chrome.dart';
import 'douri_motion.dart';
import '../theme/douri_colors.dart';

/// Shared card shell: dark card surface, subtle border, rounded corners.
class DouriCard extends StatelessWidget {
  const DouriCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(DouriSpacing.lg),
      decoration: BoxDecoration(
        color: context.douriColors.card,
        borderRadius: DouriRadius.card,
        border: Border.all(color: context.douriColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: DouriRadius.card, child: card),
    );
  }
}

/// Shop card used on Home and Explore. Hero-tagged cover so the details
/// screen can animate from it. Never invents a rating: [rating] is null
/// when the shop has no reviews yet.
///
/// Press feedback is a visible 0.96 scale via [DouriPressable] (the tap is
/// handled there, not by an inner InkWell, so a tap can never fire twice).
/// [coverHeight] lets callers make image-first cards larger (home carousel
/// 190, lists 170) while the default 140 stays for compact uses.
class DouriShopCard extends StatelessWidget {
  const DouriShopCard({
    super.key,
    required this.shopId,
    required this.name,
    this.address,
    this.coverImageUrl,
    this.logoUrl,
    this.rating,
    this.reviewCount,
    this.isOpen,
    this.distanceLabel,
    this.coverHeight = 140,
    this.onTap,
  });

  final String shopId;
  final String name;
  final String? address;
  final String? coverImageUrl;
  final String? logoUrl;
  final double? rating;
  final int? reviewCount;
  final bool? isOpen;
  final String? distanceLabel;
  final double coverHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DouriPressable(
      scale: 0.96,
      onTap: onTap,
      child: DouriCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'shop-image-$shopId',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: coverHeight,
                  width: double.infinity,
                  color: context.douriColors.elevated,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      coverImageUrl != null && coverImageUrl!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: coverImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _coverFallback(context))
                          : _coverFallback(context),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                context.douriColors.background.withValues(alpha: 0.45),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                      if (rating != null)
                        Positioned(
                          left: DouriSpacing.md,
                          bottom: DouriSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.douriColors.background.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: DouriRating(value: rating!, count: reviewCount),
                          ),
                        ),
                      if (isOpen != null)
                        Positioned(
                          top: DouriSpacing.sm,
                          right: DouriSpacing.sm,
                          child: DouriStatusBadge(open: isOpen!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DouriSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6),
                  if (address != null && address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: context.douriColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  // Rating + open state live on the cover now (Stylize style);
                  // only the distance (when a real one exists) stays here.
                  if (distanceLabel != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.near_me_outlined, size: 14, color: context.douriColors.textSecondary),
                        SizedBox(width: 4),
                        Text(distanceLabel!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.douriColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback(BuildContext context) => Center(child: Icon(Icons.content_cut, size: 44, color: DouriTextStyles.accent(context)));
}

/// Compact barber/person card (used for barbers when a shop lists them;
/// today shops have no separate barber rows, so this is used for the
/// shop owner / customer rows in queue and booking lists).
class DouriBarberCard extends StatelessWidget {
  const DouriBarberCard({super.key, required this.name, this.subtitle, this.avatarUrl, this.trailing, this.onTap});
  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DouriCard(
      onTap: onTap,
      child: Row(
        children: [
          DouriAvatar(name: name, imageUrl: avatarUrl, radius: 24),
          const SizedBox(width: DouriSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Selectable service row: name, duration, price. [selected] drives the
/// lime border/check. Price is shown only when the backend provides one.
class DouriServiceCard extends StatelessWidget {
  const DouriServiceCard({
    super.key,
    required this.name,
    this.description,
    this.durationMinutes,
    this.priceLabel,
    this.selected = false,
    this.onTap,
  });
  final String name;
  final String? description;
  final int? durationMinutes;
  final String? priceLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DouriDuration.normal,
      curve: DouriCurves.standard,
      decoration: BoxDecoration(
        color: selected ? AppColors.accentSoft : context.douriColors.card,
        borderRadius: DouriRadius.card,
        border: Border.all(color: selected ? AppColors.primaryAccent : context.douriColors.border, width: selected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: DouriRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(DouriSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (description != null && description!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(description!, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      SizedBox(height: 6),
                      if (durationMinutes != null)
                        Text('$durationMinutes min', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.douriColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(width: DouriSpacing.md),
                if (priceLabel != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(priceLabel!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DouriTextStyles.accent(context))),
                  ),
                SizedBox(width: DouriSpacing.sm),
                AnimatedSwitcher(
                  duration: DouriDuration.fast,
                  child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected ? DouriTextStyles.accent(context) : context.douriColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Booking card used in My Bookings and barber booking management.
class DouriBookingCard extends StatelessWidget {
  const DouriBookingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.queueNumber,
    this.dateLabel,
    this.timeLabel,
    this.leading,
    this.actions,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final int? queueNumber;
  final String? dateLabel;
  final String? timeLabel;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DouriCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: DouriSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor)),
              ),
            ],
          ),
          SizedBox(height: DouriSpacing.md),
          Row(
            children: [
              if (dateLabel != null) ...[
                Icon(Icons.calendar_today_outlined, size: 14, color: context.douriColors.textSecondary),
                SizedBox(width: 4),
                Text(dateLabel!, style: Theme.of(context).textTheme.bodySmall),
                SizedBox(width: DouriSpacing.lg),
              ],
              if (timeLabel != null) ...[
                Icon(Icons.access_time, size: 14, color: context.douriColors.textSecondary),
                const SizedBox(width: 4),
                Text(timeLabel!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const Spacer(),
              // Local copy: `queueNumber` is a public field, so Dart cannot
              // promote it after the null check — pass the local instead.
              if (queueNumber != null)
                Builder(
                  builder: (context) {
                    final qn = queueNumber!;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                      child: DouriAnimatedCounter(
                        value: qn,
                        format: (v) => '#$v',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DouriTextStyles.accent(context)),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: DouriSpacing.md),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Queue row: big number, customer name, status badge.
class DouriQueueCard extends StatelessWidget {
  const DouriQueueCard({super.key, required this.queueNumber, required this.name, this.detail, required this.statusLabel, required this.statusColor, this.isCurrent = false, this.actions});
  final int queueNumber;
  final String name;
  final String? detail;
  final String statusLabel;
  final Color statusColor;
  final bool isCurrent;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DouriSpacing.lg),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.accentSoft : context.douriColors.card,
        borderRadius: DouriRadius.card,
        border: Border.all(color: isCurrent ? AppColors.primaryAccent : context.douriColors.border, width: isCurrent ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.douriColors.elevated, borderRadius: BorderRadius.circular(DouriRadius.md)),
            child: Text('$queueNumber', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: DouriTextStyles.accent(context))),
          ),
          const SizedBox(width: DouriSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                  child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor)),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

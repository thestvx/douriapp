import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import 'douri_chrome.dart';

/// Stylize-style visual panels (DOURI skin: lime on #111111).
///
/// The paid Stylize template is inspiration only — none of its photos or
/// code are used here. When a real image URL exists (shop cover from
/// Supabase) it is shown via CachedNetworkImage; otherwise the panel falls
/// back to an elegant dark gradient with lime iconography. No stock photos,
/// no hotlinked images, no fake imagery anywhere.
class DouriVisualPanel extends StatelessWidget {
  const DouriVisualPanel({
    super.key,
    required this.icon,
    this.imageUrl,
    this.height,
    this.iconSize = 88,
    this.child,
  });

  final IconData icon;
  final String? imageUrl;
  final double? height;
  final double iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.elevatedSurface,
            AppColors.primaryBackground,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          // Decorative lime rings (Stylize-style composition, DOURI colour).
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.14),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Bottom fade so text sitting on the panel stays readable.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primaryBackground.withValues(alpha: 0.55),
                    AppColors.primaryBackground,
                  ],
                  stops: const [0.45, 0.8, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: iconSize + 72,
              height: iconSize + 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBackground.withValues(alpha: 0.55),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: iconSize, color: AppColors.primaryAccent),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Round lime arrow button — the Stylize onboarding CTA, in DOURI lime.
/// The arrow flips direction in RTL.
class DouriRoundArrowButton extends StatelessWidget {
  const DouriRoundArrowButton({super.key, required this.onPressed, this.size = 56});
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: AppColors.primaryAccent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isRtl ? Icons.arrow_back : Icons.arrow_forward,
            color: AppColors.primaryBackground,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Featured / promo banner (Stylize home banner): large cover with a
/// gradient overlay, shop name + rating + address at the bottom and a lime
/// Book Now pill. Built only from real shop data; callers must not pass
/// invented values.
class DouriPromoBanner extends StatelessWidget {
  const DouriPromoBanner({
    super.key,
    required this.name,
    this.address,
    this.coverImageUrl,
    this.rating,
    this.reviewCount,
    this.isOpen,
    this.onTap,
    this.onBook,
    this.bookLabel,
  });

  final String name;
  final String? address;
  final String? coverImageUrl;
  final double? rating;
  final int? reviewCount;
  final bool? isOpen;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final String? bookLabel;

  @override
  Widget build(BuildContext context) {
    final hasImage = coverImageUrl != null && coverImageUrl!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DouriRadius.xl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DouriRadius.xl),
          child: Container(
            height: 190,
            width: double.infinity,
            color: AppColors.elevatedSurface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  CachedNetworkImage(
                    imageUrl: coverImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  )
                else
                  const Center(
                    child: Icon(
                      Icons.content_cut,
                      size: 64,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryBackground.withValues(alpha: 0.35),
                          AppColors.primaryBackground.withValues(alpha: 0.92),
                        ],
                        stops: const [0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
                if (isOpen != null)
                  Positioned(
                    top: DouriSpacing.md,
                    right: DouriSpacing.md,
                    child: DouriStatusBadge(open: isOpen!),
                  ),
                Positioned(
                  left: DouriSpacing.lg,
                  right: DouriSpacing.lg,
                  bottom: DouriSpacing.lg,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rating != null)
                              DouriRating(value: rating!, count: reviewCount),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (address != null && address!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                address!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onBook != null && bookLabel != null) ...[
                        const SizedBox(width: DouriSpacing.md),
                        Material(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(DouriRadius.pill),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onBook,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                bookLabel!,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppColors.primaryBackground,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/douri_colors.dart';

/// Primary (lime), secondary (dark surface) and ghost buttons with a
/// subtle press-scale feedback. All buttons are full-width by default
/// when placed in a Column; pass [expanded] false to size to content.
class DouriButton extends StatefulWidget {
  const DouriButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.variant = DouriButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final DouriButtonVariant variant;

  @override
  State<DouriButton> createState() => _DouriButtonState();
}

enum DouriButtonVariant { primary, secondary, ghost, danger }

class _DouriButtonState extends State<DouriButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final Color bg;
    final Color fg;
    final BorderSide side;
    switch (widget.variant) {
      case DouriButtonVariant.primary:
        bg = AppColors.primaryAccent;
        fg = AppColors.accentOnDark;
        side = BorderSide.none;
        break;
      case DouriButtonVariant.secondary:
        bg = context.douriColors.elevated;
        fg = context.douriColors.text;
        side = BorderSide(color: context.douriColors.border);
        break;
      case DouriButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primaryAccent;
        side = BorderSide.none;
        break;
      case DouriButtonVariant.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        side = const BorderSide(color: AppColors.danger);
        break;
    }
    final child = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          ),
          // The spinner used to touch the label — same gap as the icon.
          const SizedBox(width: DouriSpacing.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: DouriSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final button = AnimatedScale(
      scale: _scale,
      duration: DouriDuration.fast,
      curve: DouriCurves.standard,
      child: Material(
        color: bg,
        borderRadius: DouriRadius.button,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapUp: (_) => setState(() => _scale = 1),
          onTapCancel: () => setState(() => _scale = 1),
          borderRadius: DouriRadius.button,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: DouriRadius.button,
              border: Border.fromBorderSide(side),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Small circular icon button on a dark surface.
class DouriIconButton extends StatelessWidget {
  const DouriIconButton({super.key, required this.icon, required this.onPressed, this.accent = false, this.tooltip});
  final IconData icon;
  final VoidCallback? onPressed;
  final bool accent;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: accent ? AppColors.primaryAccent : context.douriColors.elevated,
      shape: CircleBorder(side: BorderSide(color: context.douriColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: accent ? AppColors.accentOnDark : context.douriColors.text),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

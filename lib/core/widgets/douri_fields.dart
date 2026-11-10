import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/douri_colors.dart';

/// Standard DOURI text field — dark surface, lime focus border.
class DouriTextField extends StatelessWidget {
  const DouriTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: context.douriColors.textSecondary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Search field with a clear button. Direction-aware (RTL/LTR safe).
/// Pass a [focusNode] when the caller wants to react to focus changes
/// (e.g. an animated glow / a cancel affordance on the Explore tab).
class DouriSearchField extends StatelessWidget {
  const DouriSearchField({super.key, required this.controller, required this.hint, this.focusNode, this.onChanged, this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, size: 20, color: context.douriColors.textSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(Icons.clear, size: 18, color: context.douriColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Phone input with a fixed country-code chip. Algeria (+213) is the
/// default; [countryCode] is display-only in this release (single market).
class DouriPhoneField extends StatelessWidget {
  const DouriPhoneField({super.key, required this.controller, this.countryCode = '+213', this.hint, this.onChanged});
  final TextEditingController controller;
  final String countryCode;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: context.douriColors.elevated,
            borderRadius: DouriRadius.button,
            border: Border.all(color: context.douriColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇩🇿', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(countryCode, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        const SizedBox(width: DouriSpacing.sm),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(hintText: hint, counterText: ''),
          ),
        ),
      ],
    );
  }
}

/// Animated 6-box OTP field. Each box animates in as it is filled and the
/// active box gets the lime border. Calls [onCompleted] once all boxes
/// are filled.
class DouriOtpField extends StatefulWidget {
  const DouriOtpField({super.key, required this.onCompleted, this.length = 6, this.enabled = true});
  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;

  @override
  State<DouriOtpField> createState() => _DouriOtpFieldState();
}

class _DouriOtpFieldState extends State<DouriOtpField> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _nodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) widget.onCompleted(code);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // OTP digits are always LTR
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          final filled = _controllers[i].text.isNotEmpty;
          final active = _nodes[i].hasFocus;
          return AnimatedContainer(
            duration: DouriDuration.fast,
            curve: DouriCurves.standard,
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: filled ? context.douriColors.elevated : context.douriColors.surface,
              borderRadius: BorderRadius.circular(DouriRadius.md),
              border: Border.all(
                color: active || filled ? AppColors.primaryAccent : context.douriColors.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onChanged(i, v),
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }),
      ),
    );
  }
}

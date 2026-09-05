import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_icons.dart';

/// The one text input in the game.
///
/// Carries its own label, validation message and optional reveal toggle so no
/// form has to assemble those from Material parts (§6).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.trailing,
    this.enabled = true,
    this.semanticLabel,
    this.showPasswordLabel,
    this.hidePasswordLabel,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// When true the field starts masked and offers a reveal toggle.
  final bool obscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Shown inside the field, to the right — e.g. a Paste button.
  final Widget? trailing;

  final bool enabled;
  final String? semanticLabel;

  /// Localized copy for the reveal toggle's accessibility label.
  final String? showPasswordLabel;
  final String? hidePasswordLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(widget.label, style: AppText.label),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          textField: true,
          label: widget.semanticLabel ?? widget.label,
          child: TextFormField(
            controller: widget.controller,
            obscureText: _hidden,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: AppText.body,
            cursorColor: AppColors.antiqueGold,
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              errorStyle: AppText.caption.copyWith(
                color: AppColors.terracottaCoral,
              ),
              suffixIcon: _suffix(),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _suffix() {
    if (widget.obscure) {
      final label = _hidden
          ? widget.showPasswordLabel
          : widget.hidePasswordLabel;
      return Semantics(
        button: true,
        label: label,
        child: IconButton(
          // 48dp minimum target (§8).
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: AppIconView(
            _hidden ? AppIcon.eye : AppIcon.eyeOff,
            size: 20,
            color: AppColors.textSecondary,
          ),
          tooltip: label,
        ),
      );
    }
    if (widget.trailing != null) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: widget.trailing,
      );
    }
    return null;
  }
}

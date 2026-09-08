import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';

/// Custom text field with label and error state
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool showVisibilityToggle;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final int? maxLength;
  final int maxLines;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: theme.typography.body.xs.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _buildTextField(context, theme),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(BuildContext context, FThemeData theme) {
    // Use FTextField password variant
    if (obscureText || showVisibilityToggle) {
      return FTextField.password(
        control: FTextFieldControl.managed(
          controller: controller,
          initial: initialValue != null ? TextEditingValue(text: initialValue!) : null,
          onChange: (value) => onChanged?.call(value.text),
        ),
        size: FTextFieldSizeVariant.md,
        label: null, // Override default label since we render it externally
        hint: hint,
        error: null, // Error is already rendered by AppTextField wrapper
        onTap: onTap,
        textInputAction: textInputAction ?? TextInputAction.done,
        enabled: !readOnly,
        maxLength: maxLength,
        maxLines: maxLines,
        autofocus: autofocus,
      );
    }

    return FTextField(
      control: FTextFieldControl.managed(
        controller: controller,
        initial: initialValue != null ? TextEditingValue(text: initialValue!) : null,
        onChange: (value) => onChanged?.call(value.text),
      ),
      size: FTextFieldSizeVariant.md,
      hint: hint,
      error: null, // Error is already rendered by AppTextField wrapper
      prefixBuilder: prefixIcon != null
          ? (context, style, variants) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  prefixIcon!,
                  const SizedBox(width: 8),
                ],
              ),
            )
          : null,
      suffixBuilder: suffixIcon != null
          ? (context, style, variants) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  suffixIcon!,
                ],
              ),
            )
          : null,
      onTap: onTap,
      textInputAction: textInputAction ?? TextInputAction.next,
      keyboardType: keyboardType,
      enabled: !readOnly,
      maxLength: maxLength,
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}

/// Text field for NIK input
class NikTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const NikTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'NIK',
      hint: 'Masukkan NIK Anda',
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      errorText: errorText,
      prefixIcon: Icon(Icons.badge_outlined),
    );
  }
}

/// Password text field
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const PasswordTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Password',
      hint: 'Masukkan password',
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      onChanged: widget.onChanged,
      obscureText: true,
      showVisibilityToggle: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      errorText: widget.errorText,
      prefixIcon: Icon(Icons.lock_outline),
    );
  }
}

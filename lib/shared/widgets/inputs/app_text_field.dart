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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase()),
          const SizedBox(height: AppSpacing.xs),
        ],
        _buildTextField(context),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(errorText!),
        ],
      ],
    );
  }

  Widget _buildTextField(BuildContext context) {
    // Use FTextField password variant
    if (obscureText || showVisibilityToggle) {
      return FTextField.password(
        control: FTextFieldControl.managed(
          controller: controller,
          initial: initialValue != null ? TextEditingValue(text: initialValue!) : null,
          onChange: (value) => onChanged?.call(value.text),
        ),
        size: FTextFieldSizeVariant.md,
        label: label != null ? Text(label!) : null,
        hint: hint,
        error: errorText != null ? Text(errorText!) : null,
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
      label: label != null ? Text(label!) : null,
      hint: hint,
      error: errorText != null ? Text(errorText!) : null,
      prefixBuilder: prefixIcon != null
          ? (context, style, variants) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  prefixIcon!,
                  const SizedBox(width: 8),
                ],
              )
          : null,
      suffixBuilder: suffixIcon != null
          ? (context, style, variants) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  suffixIcon!,
                ],
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
      prefixIcon: const Icon(Icons.badge_outlined),
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
      prefixIcon: const Icon(Icons.lock_outline),
    );
  }
}

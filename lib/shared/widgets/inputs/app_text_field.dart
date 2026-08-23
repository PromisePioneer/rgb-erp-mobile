import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _buildTextField(),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      onTap: onTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      maxLength: maxLength,
      maxLines: maxLines,
      autofocus: autofocus,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.gray400,
          fontSize: 16,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: errorText != null ? AppColors.dangerBg : AppColors.gray100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPadding,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        counterText: '',
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (showVisibilityToggle) {
      return IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.gray400,
        ),
        onPressed: null, // Handled by StatefulBuilder in parent
      );
    }
    return suffixIcon;
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
      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.gray400),
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
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Password',
      hint: 'Masukkan password',
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      errorText: widget.errorText,
      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gray400),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.gray400,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

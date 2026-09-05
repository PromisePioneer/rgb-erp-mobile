import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';

/// Primary button with loading state
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: FButton(
        onPress: isLoading ? null : onPressed,
        variant: FButtonVariant.primary,
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: LoadingIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary/outlined button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final bool isDanger;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: FButton(
        onPress: isLoading ? null : onPressed,
        variant: isDanger ? FButtonVariant.destructive : FButtonVariant.outline,
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: LoadingIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Text button with loading state
class LoadingTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const LoadingTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: LoadingIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

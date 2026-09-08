import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';

/// Error dialog with warning icon
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Mengerti',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                message,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: onDismiss ?? () => Navigator.pop(context),
                  variant: FButtonVariant.destructive,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show error dialog
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Mengerti',
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }
}

/// Success dialog with check icon
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                message,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: onDismiss ?? () => Navigator.pop(context),
                  variant: FButtonVariant.primary,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show success dialog
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }
}

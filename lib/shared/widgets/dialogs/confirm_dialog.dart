import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Confirmation dialog helper
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDanger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Ya',
    this.cancelText = 'Batal',
    this.isDanger = false,
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        if (showCancel) ...[
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? AppColors.danger : AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(80, 40),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
      ),
    );
  }
}

/// Logout confirmation dialog
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfirmDialog(
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Ya, Keluar',
      cancelText: 'Batal',
      isDanger: false,
    );
  }

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoutDialog(),
    );
  }
}

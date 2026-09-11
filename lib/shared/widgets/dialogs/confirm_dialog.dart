import 'package:flutter/material.dart';

/// Simple confirmation dialog
class ConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDanger = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Konfirmasi'),
        content: Text(message ?? 'Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDanger
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Logout confirmation dialog
class LogoutDialog {
  static Future<bool?> show(BuildContext context) async {
    return ConfirmDialog.show(
      context,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmText: 'Keluar',
      isDanger: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../core/core.dart';
import '../icons/forui_icon_map.dart';

/// Notification types for FToast
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// Extension to convert NotificationType to FToastVariant
extension NotificationTypeExtension on NotificationType {
  FToastVariant get toastVariant {
    switch (this) {
      case NotificationType.success:
        return FToastVariant.primary;
      case NotificationType.error:
        return FToastVariant.destructive;
      case NotificationType.warning:
        return FToastVariant.primary; // Fallback
      case NotificationType.info:
        return FToastVariant.primary; // Fallback
    }
  }

  IconData? get icon {
    switch (this) {
      case NotificationType.success:
        return IconMap.checkCircle;
      case NotificationType.error:
        return IconMap.xCircle;
      case NotificationType.warning:
        return IconMap.warning;
      case NotificationType.info:
        return IconMap.infoOutline;
    }
  }
}

/// Helper class for showing ForUI toast notifications
class NotificationHelper {
  /// Show a toast notification
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = context.theme;

    // Get the appropriate icon based on type
    final icon = type.icon;

    // Get the appropriate color for the icon based on type
    Color iconColor;
    switch (type) {
      case NotificationType.success:
        iconColor = theme.colors.primary;
        break;
      case NotificationType.error:
        iconColor = theme.colors.destructive;
        break;
      case NotificationType.warning:
        iconColor = AppColors.warning;
        break;
      case NotificationType.info:
        iconColor = AppColors.info;
        break;
    }

    showFToast(
      context: context,
      variant: type.toastVariant,
      title: Text(
        message,
        style: TextStyle(color: theme.colors.foreground),
      ),
      icon: icon != null ? Icon(icon, color: iconColor, size: 20) : null,
      duration: duration,
    );
  }

  /// Show success notification
  static void showSuccess(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.success);
  }

  /// Show error notification
  static void showError(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.error);
  }

  /// Show warning notification
  static void showWarning(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.warning);
  }

  /// Show info notification
  static void showInfo(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.info);
  }
}

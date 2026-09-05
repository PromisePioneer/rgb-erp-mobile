import 'package:flutter/material.dart' show BuildContext, Text, Widget;
import 'package:forui/forui.dart';

/// Extension on BuildContext to show toast notifications easily
extension AppToastExtension on BuildContext {
  AppToast get toast => AppToast.of(this);
}

/// Toast notification helper using ForUI's FToast
class AppToast {
  final BuildContext context;

  AppToast.of(this.context);

  /// Show a toast notification
  ///
  /// [message] - The message to display
  /// [style] - The toast style (success, error, warning, info)
  /// [duration] - How long to show the toast (default: 3 seconds)
  void show({
    required String message,
    AppToastStyle style = AppToastStyle.neutral,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Map AppToastStyle to FToastVariant
    FToastVariant variant;

    switch (style) {
      case AppToastStyle.success:
        variant = FToastVariant.primary;
      case AppToastStyle.error:
        variant = FToastVariant.destructive;
      case AppToastStyle.warning:
        variant = FToastVariant.destructive;
      case AppToastStyle.info:
        variant = FToastVariant.primary;
      case AppToastStyle.neutral:
        variant = FToastVariant.primary;
    }

    showFToast(
      context: context,
      title: Text(message),
      variant: variant,
      duration: duration,
    );
  }
}

/// App-specific Toast styles
enum AppToastStyle {
  /// Success style - green
  success,

  /// Error style - red
  error,

  /// Warning style - amber
  warning,

  /// Info style - uses primary color
  info,

  /// Neutral style - uses muted colors
  neutral,
}

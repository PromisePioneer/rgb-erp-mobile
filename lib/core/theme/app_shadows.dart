import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standard shadow presets for consistent card styling across the app
class AppShadows {
  AppShadows._();

  /// Card shadow - for cards on white/gradient backgrounds
  /// Clear visibility with slight elevation
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.slate300.withAlpha(128),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Card shadow with subtle elevation
  static List<BoxShadow> get cardSubtle => [
        BoxShadow(
          color: AppColors.slate200.withAlpha(102),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Card shadow with stronger elevation
  static List<BoxShadow> get cardElevated => [
        BoxShadow(
          color: AppColors.slate300.withAlpha(153),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Button shadow
  static List<BoxShadow> get button => [
        BoxShadow(
          color: AppColors.slate300.withAlpha(102),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating button shadow
  static List<BoxShadow> get floatingButton => [
        BoxShadow(
          color: AppColors.slate400.withAlpha(77),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

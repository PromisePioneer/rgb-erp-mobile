import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_colors.dart';

/// Forui theme configuration with custom app colors.
class AppFTheme {
  AppFTheme._();

  /// Default light theme with app color customization
  static FThemeData get light => FThemeData(
        colors: FColors.neutralLight.copyWith(
          primary: AppColors.primary,
          primaryForeground: AppColors.white,
          destructive: AppColors.danger,
          destructiveForeground: AppColors.white,
          error: AppColors.danger,
          errorForeground: AppColors.white,
        ),
        typography: FTheme.neutral.light.touch.typography,
        style: FTheme.neutral.light.touch.style,
        touch: true,
        debugLabel: 'RGB 86 Light',
      );

  /// Default dark theme with app color customization
  static FThemeData get dark => FThemeData(
        colors: FColors.neutralDark.copyWith(
          primary: AppColors.primaryLight,
          primaryForeground: AppColors.white,
          destructive: AppColors.danger,
          destructiveForeground: AppColors.white,
          error: AppColors.danger,
          errorForeground: AppColors.white,
        ),
        typography: FTheme.neutral.dark.touch.typography,
        style: FTheme.neutral.dark.touch.style,
        touch: true,
        debugLabel: 'RGB 86 Dark',
      );
}

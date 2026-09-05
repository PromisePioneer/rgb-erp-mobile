import 'package:flutter/material.dart' show Color, Brightness, SystemUiOverlayStyle;
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Main app theme configuration using ForUI
class AppTheme {
  AppTheme._();

  /// Default light theme using ForUI
  static FThemeData get light => FTheme.neutral.light.touch;

  /// Default dark theme using ForUI
  static FThemeData get dark => FTheme.neutral.dark.touch;
}

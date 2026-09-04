import 'package:forui/forui.dart';

/// Forui theme configuration.
class AppFTheme {
  AppFTheme._();

  /// Default light theme (Forui neutral dark - black buttons)
  static FThemeData get light => FTheme.neutral.light.touch;

  /// Default dark theme
  static FThemeData get dark => FTheme.neutral.dark.touch;
}

import 'package:flutter/material.dart';

/// Global keys for tutorial targets
/// These keys are used to highlight specific UI elements during onboarding
class TutorialKeys {
  TutorialKeys._();

  /// Key for the menu grid container on dashboard
  static final GlobalKey menuGridKey = GlobalKey();

  /// Key for the notification button
  static final GlobalKey notificationKey = GlobalKey();

  /// Key for the panic/SOS button
  static final GlobalKey panicButtonKey = GlobalKey();

  /// Key for home tab in bottom nav
  static final GlobalKey homeKey = GlobalKey();

  /// Key for presensi tab in bottom nav
  static final GlobalKey presensiKey = GlobalKey();

  /// Key for For You tab in bottom nav
  static final GlobalKey forYouKey = GlobalKey();

  /// Key for Akun tab in bottom nav
  static final GlobalKey akunKey = GlobalKey();

  /// Key for scan FAB button
  static final GlobalKey scanButtonKey = GlobalKey();

  /// Key for face enrollment menu item
  static final GlobalKey faceEnrollmentKey = GlobalKey();

  /// Key for schedule menu item
  static final GlobalKey scheduleKey = GlobalKey();

  /// Key for leave menu item
  static final GlobalKey leaveKey = GlobalKey();

  /// Key for payroll menu item
  static final GlobalKey payrollKey = GlobalKey();

  /// Reset all keys (useful for testing)
  static void resetAll() {
    // Note: GlobalKeys can't be truly reset, but this signals intent
    // In practice, keys should only be set once per app lifecycle
  }
}

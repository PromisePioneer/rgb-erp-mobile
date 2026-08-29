import 'dart:async';
import 'package:flutter/material.dart';

/// Global overlay entry key - attach to MaterialApp
final globalNotificationOverlayKey = GlobalKey<NavigatorState>();

/// Simple overlay manager for showing notification dialogs
class GlobalNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Show a dialog widget over the entire app
  static void show(Widget dialog) {
    // Remove existing entry first
    hide();

    _currentEntry = OverlayEntry(
      builder: (context) => dialog,
    );

    final state = globalNotificationOverlayKey.currentState;
    if (state != null) {
      state.overlay?.insert(_currentEntry!);
    } else {
      // Delay if overlay not ready yet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalNotificationOverlayKey.currentState?.overlay?.insert(_currentEntry!);
      });
    }
  }

  /// Hide current overlay
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

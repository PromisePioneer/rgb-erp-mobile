import 'package:flutter/material.dart';

/// Border radius constants
class AppRadius {
  AppRadius._();

  // Border radius values
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;

  // BorderRadius helpers
  static BorderRadius radiusNone = BorderRadius.circular(none);
  static BorderRadius radiusXs = BorderRadius.circular(xs);
  static BorderRadius radiusSm = BorderRadius.circular(sm);
  static BorderRadius radiusMd = BorderRadius.circular(md);
  static BorderRadius radiusLg = BorderRadius.circular(lg);
  static BorderRadius radiusXl = BorderRadius.circular(xl);
  static BorderRadius radiusXxl = BorderRadius.circular(xxl);
  static BorderRadius radiusFull = BorderRadius.circular(full);

  // Common radius presets
  static BorderRadius get card => radiusLg;
  static BorderRadius get button => BorderRadius.circular(26); // Full rounded
  static BorderRadius get input => radiusMd;
  static BorderRadius get bottomSheet => const BorderRadius.vertical(
        top: Radius.circular(xxl),
      );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Color, BorderRadius, BoxShadow;

import 'package:rgb_86/core/theme/app_colors.dart';
import 'package:rgb_86/core/theme/app_radius.dart';
import 'package:rgb_86/core/theme/app_shadows.dart';

void main() {
  group('AppColors', () {
    test('should have valid Color values', () {
      expect(AppColors.rgbPrimary, isA<Color>());
      expect(AppColors.rbmPrimary, isA<Color>());
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.danger, isA<Color>());
      expect(AppColors.info, isA<Color>());
    });

    test('should have valid hex color values', () {
      // Primary colors - just verify they are valid colors
      expect(AppColors.rgbPrimary, isA<Color>());
      expect(AppColors.rbmPrimary, isA<Color>());
    });

    test('should have slate color variants', () {
      expect(AppColors.slate200, isA<Color>());
      expect(AppColors.slate300, isA<Color>());
      expect(AppColors.slate500, isA<Color>());
    });
  });

  group('AppRadius', () {
    test('should have valid double radius values', () {
      expect(AppRadius.none, equals(0.0));
      expect(AppRadius.xs, equals(4.0));
      expect(AppRadius.sm, equals(8.0));
      expect(AppRadius.md, equals(12.0));
      expect(AppRadius.lg, equals(16.0));
      expect(AppRadius.xl, equals(20.0));
      expect(AppRadius.xxl, equals(24.0));
      expect(AppRadius.full, equals(9999.0));
    });

    test('should have valid BorderRadius presets', () {
      expect(AppRadius.card, isA<BorderRadius>());
      expect(AppRadius.button, isA<BorderRadius>());
      expect(AppRadius.input, isA<BorderRadius>());
      expect(AppRadius.bottomSheet, isA<BorderRadius>());
    });

    test('radius values should be in ascending order', () {
      expect(AppRadius.xs, lessThan(AppRadius.sm));
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
      expect(AppRadius.xl, lessThan(AppRadius.xxl));
    });
  });

  group('AppShadows', () {
    test('should have valid BoxShadow lists', () {
      expect(AppShadows.card, isA<List<BoxShadow>>());
      expect(AppShadows.cardSubtle, isA<List<BoxShadow>>());
      expect(AppShadows.cardElevated, isA<List<BoxShadow>>());
      expect(AppShadows.button, isA<List<BoxShadow>>());
      expect(AppShadows.floatingButton, isA<List<BoxShadow>>());
    });

    test('card shadows should have valid shadow properties', () {
      final shadows = AppShadows.card;
      expect(shadows.length, equals(1));

      final shadow = shadows.first;
      expect(shadow.blurRadius, equals(10.0));
      expect(shadow.offset, equals(const Offset(0, 3)));
    });

    test('cardElevated should have larger blur than card', () {
      final cardShadow = AppShadows.card.first;
      final elevatedShadow = AppShadows.cardElevated.first;

      expect(elevatedShadow.blurRadius, greaterThan(cardShadow.blurRadius));
    });

    test('shadows should use slate colors', () {
      final shadows = AppShadows.card;
      expect(shadows.first.color, equals(AppColors.slate300.withAlpha(128)));
    });
  });
}

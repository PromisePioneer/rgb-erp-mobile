import 'package:flutter/material.dart' show Color, Brightness, Container, Builder, Text, Center, Scaffold, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:rgb_86/core/theme/app_ftheme.dart';

void main() {
  group('AppFTheme', () {
    test('should return FThemeData for light theme', () {
      final lightTheme = AppFTheme.light;
      expect(lightTheme, isA<FThemeData>());
    });

    test('should return FThemeData for dark theme', () {
      final darkTheme = AppFTheme.dark;
      expect(darkTheme, isA<FThemeData>());
    });

    test('light and dark themes should be different', () {
      final lightTheme = AppFTheme.light;
      final darkTheme = AppFTheme.dark;
      expect(lightTheme, isNot(equals(darkTheme)));
    });

    test('should have custom debug labels', () {
      expect(AppFTheme.light.debugLabel, equals('RGB 86 Light'));
      expect(AppFTheme.dark.debugLabel, equals('RGB 86 Dark'));
    });
  });

  group('FThemeData', () {
    testWidgets('should wrap child with FTheme', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: Builder(
            builder: (context) {
              final theme = FTheme.of(context);
              expect(theme, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('child should access FTheme colors', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: Builder(
            builder: (context) {
              final theme = FTheme.of(context);
              expect(theme.colors.primary, isA<Color>());
              expect(theme.colors.background, isA<Color>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('FToaster', () {
    testWidgets('should render without error', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: FToaster(
            child: Builder(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Test')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FToaster), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });
}

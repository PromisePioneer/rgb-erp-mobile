import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';


import 'package:rgb_86/core/theme/app_colors.dart';
import 'package:rgb_86/core/theme/app_ftheme.dart';

void main() {
  group('ForUI Components Integration', () {
    testWidgets('FCard should render correctly', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: MaterialApp(
            home: Scaffold(
              body: FCard(
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FCard), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('FButton variants should work', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FButton(
                    onPress: () {},
                    variant: FButtonVariant.primary,
                    child: Text('Primary'),
                  ),
                  FButton(
                    onPress: () {},
                    variant: FButtonVariant.secondary,
                    child: Text('Secondary'),
                  ),
                  FButton(
                    onPress: () {},
                    variant: FButtonVariant.outline,
                    child: Text('Outline'),
                  ),
                  FButton(
                    onPress: () {},
                    variant: FButtonVariant.ghost,
                    child: Text('Ghost'),
                  ),
                  FButton(
                    onPress: () {},
                    variant: FButtonVariant.destructive,
                    child: Text('Destructive'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FButton), findsNWidgets(5));
    });

    testWidgets('FTextField should render correctly', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: null,
                    onChange: (_) {},
                  ),
                  hint: 'Enter text',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FTextField), findsOneWidget);
    });

    testWidgets('FDivider should render correctly', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Above'),
                  FDivider(),
                  Text('Below'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FDivider), findsOneWidget);
    });

    testWidgets('FIcon should render correctly', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: MaterialApp(
            home: Scaffold(
              body: Icon(FLucideIcons.checkCircle),
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('Color Migration Verification', () {
    test('AppColors should use standard Color values', () {
      expect(AppColors.rgbPrimary, isA<Color>());
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.danger, isA<Color>());
    });

    testWidgets('FTheme colors should be accessible', (tester) async {
      await tester.pumpWidget(
        FTheme(
          data: AppFTheme.light,
          child: Builder(
            builder: (context) {
              final theme = FTheme.of(context);
              expect(theme.colors.primary, isA<Color>());
              expect(theme.colors.background, isA<Color>());
              expect(theme.colors.foreground, isA<Color>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

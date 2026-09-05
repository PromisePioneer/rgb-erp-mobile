import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:rgb_86/shared/widgets/inputs/app_text_field.dart';

void main() {
  group('AppTextField', () {
    testWidgets('should display label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Email',
              hint: 'Enter email',
            ),
          ),
        ),
      );

      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets('should display hint when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Email',
              hint: 'Enter email',
            ),
          ),
        ),
      );

      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('should display error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Email',
              hint: 'Enter email',
              errorText: 'Invalid email',
            ),
          ),
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('should call onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Name',
              hint: 'Enter name',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(FTextField), 'John');
      await tester.pump();

      expect(changedValue, equals('John'));
    });

    testWidgets('should use controller when provided', (tester) async {
      final controller = TextEditingController(text: 'Initial');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Name',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('should use FTextField for input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Test',
            ),
          ),
        ),
      );

      expect(find.byType(FTextField), findsOneWidget);
    });
  });

  group('NikTextField', () {
    testWidgets('should have NIK label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NikTextField(),
          ),
        ),
      );

      expect(find.text('NIK'), findsOneWidget);
    });
  });

  group('PasswordTextField', () {
    testWidgets('should have Password label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordTextField(),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
    });
  });
}

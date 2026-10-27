import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/core/auth/biometric_auth_service.dart';
import 'package:openimis_claim_policy_app/feature/login/views/login_page.dart';

void main() {
  group('LoginPage Tests', () {
    testWidgets('LoginPage renders all essential widgets', (
      WidgetTester tester,
    ) async {
      // Build the LoginPage widget wrapped in necessary providers
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );

      // Wait for all animations and async operations to complete
      await tester.pumpAndSettle();

      // Verify that the login page renders
      expect(find.text('openIMIS Login'), findsOneWidget);
      expect(find.text('Sign in with your openIMIS account'), findsOneWidget);

      // Verify username and password fields exist
      expect(find.text('User Name'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify buttons exist
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.text(
          'Claim Administrator setup is requested only when you open a Claims feature.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides fingerprint action until biometric login is enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            biometricAvailableProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
      expect(find.text('Use biometrics'), findsNothing);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Username and password fields accept input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );
      await tester.pumpAndSettle();

      // Find the text fields
      final usernameFinder = find.byType(TextField).at(0);
      final passwordFinder = find.byType(TextField).at(1);

      // Enter text into username field
      await tester.enterText(usernameFinder, 'testuser');
      expect(
        tester.widget<TextField>(usernameFinder).controller?.text,
        'testuser',
      );

      // Enter text into password field
      await tester.enterText(passwordFinder, 'testpassword');
      expect(
        tester.widget<TextField>(passwordFinder).controller?.text,
        'testpassword',
      );
    });

    testWidgets('Password visibility toggle works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );
      await tester.pumpAndSettle();

      // Find the password field
      final passwordField = find.byType(TextField).at(1);
      expect(passwordField, findsOneWidget);

      // Verify password is initially obscured
      TextField passwordTextField = tester.widget(passwordField);
      expect(passwordTextField.obscureText, true);

      // Tap the visibility toggle button
      final visibilityToggle = find.ancestor(
        of: find.byIcon(Icons.visibility_off),
        matching: find.byType(IconButton),
      );
      expect(visibilityToggle, findsOneWidget);
      await tester.ensureVisible(visibilityToggle);
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Verify password is now visible
      passwordTextField = tester.widget(passwordField);
      expect(passwordTextField.obscureText, false);

      // Verify the icon changed
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Login button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );

      // Wait for all animations and async operations to complete
      await tester.pumpAndSettle();

      // Find the login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButton, findsOneWidget);

      // Verify button is enabled
      final ElevatedButton button = tester.widget(loginButton);
      expect(button.enabled, true);
    });

    testWidgets('Claims setup is described as feature-specific', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginPage(title: 'Login Test')),
        ),
      );

      expect(
        find.text(
          'Claim Administrator setup is requested only when you open a Claims feature.',
        ),
        findsOneWidget,
      );
    });
  });
}

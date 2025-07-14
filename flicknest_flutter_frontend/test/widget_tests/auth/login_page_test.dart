import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/auth/presentation/pages/login_page.dart';
import '../../test_utils.dart';

void main() {
  group('Login Page Widget Tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = TestUtils.getMockAuth();
    });

    testWidgets('renders login page UI correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('FlickNest'), findsOneWidget);
      expect(find.text('Your Smart Home Entertainment Hub'), findsOneWidget);
      expect(find.byType(SignInButton), findsOneWidget);
    });

    testWidgets('shows loading indicator during Google sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Simulate button press
      await tester.tap(find.byType(SignInButton));
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigates to home page on successful Google sign-in', (WidgetTester tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Simulate button press
      await tester.tap(find.byType(SignInButton));
      await tester.pumpAndSettle();

      // Verify navigation to home page
      expect(find.text('FlickNest'), findsNothing);
    });

    testWidgets('displays error message on Google sign-in failure', (WidgetTester tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: false);

      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Simulate button press
      await tester.tap(find.byType(SignInButton));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.textContaining('Failed to sign in'), findsOneWidget);
    });
  });
}

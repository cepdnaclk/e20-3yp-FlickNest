import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../test_utils.dart';

final firebaseAuthProvider = Provider((ref) => MockFirebaseAuth());

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login Page')),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home Page')),
      ),
      GoRoute(
        path: '/rooms/room123',
        builder: (context, state) => const Scaffold(body: Text('Room Details')),
      ),
      GoRoute(
        path: '/invalid-route',
        builder: (context, state) => const Scaffold(body: Text('Page Not Found')),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Text('Splash Page')),
      ),
      GoRoute(
        path: '/invitations',
        builder: (context, state) => const Scaffold(body: Text('Invitations Page')),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const Scaffold(body: Text('About FlickNest Page')),
      ),
    ],
  );
}

void setupMockUserRole(MockFirebaseAuth mockAuth, String role) {
  // Mock implementation to set the user role for testing purposes.
  // This can be extended to simulate role-based behavior.
  // For now, it does nothing as a placeholder.
}

void main() {
  group('Router Tests', () {
    late GoRouter router;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = TestUtils.getMockAuth();
      router = createRouter();
    });

    testWidgets('unauthenticated user redirected to login', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/login');
    });

    testWidgets('authenticated user sees home page', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/');
    });

    testWidgets('deep linking to room details works', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/rooms/room123');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/rooms/room123');
      expect(find.text('Room Details'), findsOneWidget);
    });

    testWidgets('invalid routes redirect to 404', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/invalid-route');
      await tester.pumpAndSettle();

      expect(find.text('Page Not Found'), findsOneWidget);
    });

    testWidgets('navigation guards work for admin routes', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);
      // Setup non-admin role
      TestUtils.setupMockUserRole(mockAuth, 'user');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/admin');
      await tester.pumpAndSettle();

      // Should be redirected away from admin page
      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/');
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('back navigation works correctly', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Navigate through a few pages
      router.go('/rooms');
      await tester.pumpAndSettle();
      router.go('/rooms/room123');
      await tester.pumpAndSettle();

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/rooms');
    });

    testWidgets('navigates to splash page', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/splash');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/splash');
      expect(find.text('Splash Page'), findsOneWidget);
    });

    testWidgets('navigates to invitations page', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/invitations');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/invitations');
      expect(find.text('Invitations Page'), findsOneWidget);
    });

    testWidgets('navigates to room details page with parameters', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/rooms/room123', extra: {
        'environmentId': 'env1',
        'roomId': 'room123',
        'roomName': 'Test Room',
      });
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/rooms/room123');
      expect(find.text('Room Details'), findsOneWidget);
    });

    testWidgets('navigates to about page', (tester) async {
      TestUtils.setupMockAuthState(mockAuth, isLoggedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/about');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration?.uri.toString(), '/about');
      expect(find.text('About FlickNest Page'), findsOneWidget);
    });
  });
}

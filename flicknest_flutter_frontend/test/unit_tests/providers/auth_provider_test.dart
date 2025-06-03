import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock class for Firebase User
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Authentication Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Current User Provider Tests', () {
      test('currentAuthUserProvider should initially be loading', () {
        final result = container.read(currentAuthUserProvider);
        expect(result.isLoading, true);
      });

      test('currentAuthUserProvider reflects authenticated state', () {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
          displayName: 'Nuwan Dilshan'
        );

        // Override the auth provider with authenticated user
        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(mockUser))
          ],
        );

        // Initial state should contain the mock user
        final authState = container.read(currentAuthUserProvider);
        expect(authState.value?.uid, 'Hv03hlt99gTXsq5zOrmqdYo5MPF2');
        expect(authState.value?.email, 'wmndilshan@gmail.com');
      });

      test('currentUserIdProvider returns empty string when not authenticated', () {
        // Override with no user (unauthenticated state)
        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(null))
          ],
        );

        final userId = container.read(currentUserIdProvider);
        expect(userId, '');
      });

      test('currentUserIdProvider returns correct ID when authenticated', () {
        final mockUser = MockUser(
          uid: 'zLpSk1cJt4PCxm43wjvi0SWqAx62',
          email: 'e20455@eng.pdn.ac.lk'
        );

        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(mockUser))
          ],
        );

        final userId = container.read(currentUserIdProvider);
        expect(userId, 'zLpSk1cJt4PCxm43wjvi0SWqAx62');
      });

      test('currentUserEmailProvider returns null when not authenticated', () {
        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(null))
          ],
        );

        final userEmail = container.read(currentUserEmailProvider);
        expect(userEmail, null);
      });

      test('currentUserEmailProvider returns correct email when authenticated', () {
        final mockUser = MockUser(
          uid: 'kZnzMGo0TbbVOdUqhvWwYlrMYH32',
          email: 'surajwijesooriya47@gmail.com'
        );

        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(mockUser))
          ],
        );

        final userEmail = container.read(currentUserEmailProvider);
        expect(userEmail, 'surajwijesooriya47@gmail.com');
      });

      test('auth state changes are properly reflected', () async {
        // Start with authenticated user
        final mockUser = MockUser(
          uid: 'jgjGKOqgZDTSHuRcsjeP9CpDkV52',
          email: 'dilshannuwan06@gmail.com'
        );

        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(mockUser))
          ],
        );

        // Verify initial auth state
        expect(container.read(currentUserIdProvider), 'jgjGKOqgZDTSHuRcsjeP9CpDkV52');
        expect(container.read(currentUserEmailProvider), 'dilshannuwan06@gmail.com');

        // Simulate logout
        container = ProviderContainer(
          overrides: [
            currentAuthUserProvider.overrideWith((ref) =>
              Stream.value(null))
          ],
        );

        // Verify logged out state
        expect(container.read(currentUserIdProvider), '');
        expect(container.read(currentUserEmailProvider), null);
      });
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:flicknest_flutter_frontend/providers/database_provider.dart';
import 'package:flicknest_flutter_frontend/providers/role/role_provider.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';
import '../../test_utils.dart';

// Mock implementation of Firebase User
class MockUser extends Mock implements User {
  @override
  final String uid;
  @override
  final String? email;

  MockUser({required this.uid, this.email});
}

// Mock implementation of EnvironmentNotifier
class MockEnvironmentNotifier extends EnvironmentNotifier {
  @override
  String? state;

  MockEnvironmentNotifier(this.state);

  @override
  Future<void> setEnvironment(String environmentId) async {
    state = environmentId;
  }

  @override
  Future<void> clearEnvironment() async {
    state = null;
  }
}

void main() {
  group('Role Provider Tests', () {
    late ProviderContainer container;
    late MockFirebaseDatabase mockDb;

    final mockData = {
      "environments": {
        "-ORZ-QSZUyoPQKENzK3I": {
          "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
          "name": "fourth",
          "users": {
            "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
              "addedAt": 1748655781877,
              "email": "wmndilshan@gmail.com",
              "name": "Nuwan Dilshan",
              "role": "admin"
            },
            "zLpSk1cJt4PCxm43wjvi0SWqAx62": {
              "role": "co-admin"
            }
          }
        }
      },
      "users": {
        "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
          "environments": {
            "-ORZ-QSZUyoPQKENzK3I": "admin"
          }
        }
      }
    };

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
      TestUtils.setupMockDatabaseResponse(mockDb, mockData);
    });

    tearDown(() {
      container.dispose();
    });

    group('currentUserRoleProvider Tests', () {
      test('should return role from environments path', () async {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final role = await container.read(currentUserRoleProvider.future);

        expect(role, equals('admin'));
      });

      test('should return role from users path', () async {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final role = await container.read(currentUserRoleProvider.future);

        expect(role, equals('admin'));
      });

      test('should return null if no role is found', () async {
        final mockUser = MockUser(
          uid: 'nonexistentUser',
          email: 'nonexistent@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final role = await container.read(currentUserRoleProvider.future);

        expect(role, isNull);
      });
    });

    group('isAdminProvider Tests', () {
      test('should return true if user is admin', () {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isAdmin = container.read(isAdminProvider);

        expect(isAdmin, isTrue);
      });

      test('should return false if user is not admin', () {
        final mockUser = MockUser(
          uid: 'zLpSk1cJt4PCxm43wjvi0SWqAx62',
          email: 'coadmin@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isAdmin = container.read(isAdminProvider);

        expect(isAdmin, isFalse);
      });
    });

    group('isCoAdminProvider Tests', () {
      test('should return true if user is co-admin', () {
        final mockUser = MockUser(
          uid: 'zLpSk1cJt4PCxm43wjvi0SWqAx62',
          email: 'coadmin@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isCoAdmin = container.read(isCoAdminProvider);

        expect(isCoAdmin, isTrue);
      });

      test('should return false if user is not co-admin', () {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isCoAdmin = container.read(isCoAdminProvider);

        expect(isCoAdmin, isFalse);
      });
    });

    group('isUserProvider Tests', () {
      test('should return true if user is basic user', () {
        final mockUser = MockUser(
          uid: 'basicUserId',
          email: 'basicuser@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isUser = container.read(isUserProvider);

        expect(isUser, isTrue);
      });

      test('should return false if user is not basic user', () {
        final mockUser = MockUser(
          uid: 'Hv03hlt99gTXsq5zOrmqdYo5MPF2',
          email: 'wmndilshan@gmail.com',
        );

        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWith((ref) => mockDb),
            currentEnvironmentProvider.overrideWith(
              (ref) => MockEnvironmentNotifier("-ORZ-QSZUyoPQKENzK3I"),
            ),
            currentAuthUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          ],
        );

        final isUser = container.read(isUserProvider);

        expect(isUser, isFalse);
      });
    });
  });
}

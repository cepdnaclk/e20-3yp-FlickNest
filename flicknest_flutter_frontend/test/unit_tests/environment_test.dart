import 'package:flicknest_flutter_frontend/providers/database_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../test_utils.dart';

// Mock models for testing
class Environment {
  final String? name;
  final Map<String, dynamic> users;
  final Map<String, dynamic> devices;
  final Map<String, dynamic> rooms;

  Environment({
    this.name,
    this.users = const {},
    this.devices = const {},
    this.rooms = const {},
  });
}

final mockEnvironmentProvider = Provider.family<Environment, String>((ref, envId) {
  return Environment(
    name: "Test Environment",
    users: {},
    devices: {},
    rooms: {},
  );
});

final mockUserEnvironmentsProvider = Provider.family<List<Environment>, String>((ref, userId) {
  return [];
});

void main() {
  group('Environment Tests', () {
    late ProviderContainer container;
    late MockFirebaseDatabase mockDb;

    final mockData = {
      "environments": {
        "-OROy6daKl5r6im0nDrb": {
          "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
          "name": "Second",
          "users": {
            "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
              "email": "wmndilshan@gmail.com",
              "handbandId": "",
              "name": "Nuwan Dilshan",
              "photoUrl": "https://lh3.googleusercontent.com/a/ACg8ocJ1AgKX-qpvOosiIyClvceQyqqaDermqh0RYAkfcqLXJjAPGg=s96-c",
              "role": "admin"
            }
          }
        },
        "-ORZ-QSZUyoPQKENzK3I": {
          "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
          "createdAt": 1748655781877,
          "name": "fourth",
          "users": {
            "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
              "addedAt": 1748655781877,
              "email": "wmndilshan@gmail.com",
              "name": "Nuwan Dilshan",
              "role": "admin"
            },
            "zLpSk1cJt4PCxm43wjvi0SWqAx62": {
              "addedAt": 1748655781877,
              "email": "e20455@eng.pdn.ac.lk",
              "name": "Anonymous",
              "role": "co-admin"
            }
          }
        },
        "env_12345": {
          "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
          "name": "Smart Home",
          "devices": {
            "dev_1001": {
              "allowedUsers": {"user_001": true},
              "assignedSymbol": "sym_001",
              "name": "Living Room Light",
              "roomId": "room_001",
              "state": false
            }
          },
          "rooms": {
            "room_001": {
              "devices": {"dev_1001": true},
              "name": "Living Room"
            }
          },
          "users": {
            "user_001": {
              "controllableDevices": {
                "dev_1001": true
              },
              "handbandId": "hb_001",
              "name": "Alice",
              "role": "admin"
            }
          }
        }
      }
    };

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
      TestUtils.setupMockDatabaseResponse(mockDb, mockData);
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Environment Access Tests', () {
      test('fetchUserEnvironments returns all environments user has access to', () async {
        final userId = "Hv03hlt99gTXsq5zOrmqdYo5MPF2";
        final environments = await container.read(mockUserEnvironmentsProvider(userId));

        expect(environments, isNotNull);
        expect(environments.length, 3);
        final names = environments.map((e) => e.name).toList();
        expect(names, contains("Second"));
        expect(names, contains("fourth"));
        expect(names, contains("Smart Home"));
      });

      test('verifies user roles in environment', () async {
        final envId = "-ORZ-QSZUyoPQKENzK3I";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        expect(environment.users["Hv03hlt99gTXsq5zOrmqdYo5MPF2"]?["role"], "admin");
        expect(environment.users["zLpSk1cJt4PCxm43wjvi0SWqAx62"]?["role"], "co-admin");
      });
    });

    group('Device Management Tests', () {
      test('fetches devices with correct permissions', () async {
        final envId = "env_12345";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        final device = environment.devices["dev_1001"];
        expect(device, isNotNull);
        expect(device["name"], "Living Room Light");
        expect(device["allowedUsers"]?["user_001"], true);
        expect(device["assignedSymbol"], "sym_001");
      });

      test('validates device access permissions', () async {
        final envId = "env_12345";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        final device = environment.devices["dev_1001"];
        expect(device, isNotNull);
        expect(device["allowedUsers"]?["user_001"], true);
        expect(device["allowedUsers"]?["user_002"], null);
      });
    });

    group('Room Management Tests', () {
      test('rooms contain correct device associations', () async {
        final envId = "env_12345";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        final room = environment.rooms["room_001"];
        expect(room, isNotNull);
        expect(room["name"], "Living Room");
        expect(room["devices"]?["dev_1001"], true);
      });
    });

    group('User Management Tests', () {
      test('handles user handband assignments', () async {
        final envId = "env_12345";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        final user = environment.users["user_001"];
        expect(user, isNotNull);
        expect(user["handbandId"], "hb_001");
        expect(user["controllableDevices"]?["dev_1001"], true);
      });

      test('validates user roles and permissions', () async {
        final envId = "-ORZ-QSZUyoPQKENzK3I";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        expect(environment.users["Hv03hlt99gTXsq5zOrmqdYo5MPF2"]?["role"], "admin");
        expect(environment.users["zLpSk1cJt4PCxm43wjvi0SWqAx62"]?["role"], "co-admin");
      });

      test('tracks user addition timestamps', () async {
        final envId = "-ORZ-QSZUyoPQKENzK3I";
        final environment = await container.read(mockEnvironmentProvider(envId));

        expect(environment, isNotNull);
        final user = environment.users["Hv03hlt99gTXsq5zOrmqdYo5MPF2"];
        expect(user, isNotNull);
        expect(user["addedAt"], 1748655781877);
      });
    });
  });
}

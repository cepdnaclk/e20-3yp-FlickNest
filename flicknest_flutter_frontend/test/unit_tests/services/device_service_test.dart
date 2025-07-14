import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flicknest_flutter_frontend/providers/devices/device_provider.dart';
import 'package:flicknest_flutter_frontend/features/devices/domain/device.dart';
import 'package:flicknest_flutter_frontend/providers/database_provider.dart';
import '../../test_utils.dart';

void main() {
  group('Device Provider Tests', () {
    late ProviderContainer container;
    late MockFirebaseDatabase mockDb;

    final mockEnvId = "env_12345";
    final mockDeviceData = {
      "environments": {
        "env_12345": {
          "devices": {
            "dev_1001": {
              "allowedUsers": {"user_001": true},
              "assignedSymbol": "sym_001",
              "name": "Living Room Light",
              "roomId": "room_001",
              "state": false,
              "type": "Light",
              "status": "online"
            },
            "dev_1010": {
              "allowedUsers": {"user_003": true},
              "assignedSymbol": "sym_010",
              "name": "Kitchen Light",
              "roomId": "room_005",
              "state": true,
              "type": "Light",
              "status": "online"
            }
          }
        }
      },
      "symbols": {
        "sym_001": {
          "available": false,
          "name": "circle",
          "source": "broker",
          "state": false
        },
        "sym_016": {
          "available": true,
          "name": "arise",
          "source": "broker",
          "state": true
        }
      }
    };

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
      TestUtils.setupMockDatabaseResponse(mockDb, mockDeviceData);
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchDevices should return all devices in environment', () async {
      final devices = await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);

      expect(devices.length, 2);
      expect(devices.any((d) => d.name == "Living Room Light"), true);
      expect(devices.any((d) => d.name == "Kitchen Light"), true);
    });

    test('getDeviceById should return correct device', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));

      expect(device?.name, "Living Room Light");
      expect(device?.roomId, "room_001");
      expect(device?.assignedSymbol, "sym_001");
      expect(device?.state, false);
    });

    test('devicesByRoom should return correct devices', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      final roomDevices = container.read(devicesByRoomProvider(mockEnvId, "room_001"));

      expect(roomDevices.length, 1);
      expect(roomDevices.first.name, "Living Room Light");
      expect(roomDevices.first.roomId, "room_001");
    });

    test('devicesByType should return correct devices', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      final typeDevices = container.read(devicesByTypeProvider(mockEnvId, "Light"));

      expect(typeDevices.length, 2);
      expect(typeDevices.every((d) => d.type == "Light"), true);
    });

    test('updateDeviceState should change device state', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      await container.read(devicesProvider.notifier).updateDeviceState(mockEnvId, "dev_1001", true);

      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));
      expect(device?.state, true);
    });

    test('updateDeviceSymbol should update assigned symbol', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      await container.read(devicesProvider.notifier).updateDeviceSymbol(mockEnvId, "dev_1001", "sym_002");

      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));
      expect(device?.assignedSymbol, "sym_002");
    });

    test('addDevice should create new device', () async {
      final newDevice = Device(
        id: 'dev_1016',
        name: 'New Device',
        type: 'Light',
        roomId: 'room_001',
        status: 'online',
        state: false,
        assignedSymbol: 'sym_016'
      );

      await container.read(devicesProvider.notifier).addDevice(mockEnvId, newDevice);
      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1016"));

      expect(device?.id, 'dev_1016');
      expect(device?.name, 'New Device');
    });

    test('deleteDevice should remove device', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      await container.read(devicesProvider.notifier).deleteDevice(mockEnvId, "dev_1001");

      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));
      expect(device, isNull);
    });

    test('should handle device user permissions', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));

      expect(device?.allowedUsers?["user_001"], true);
      expect(device?.allowedUsers?["user_002"], isNull);
    });

    test('should track device status', () async {
      await container.read(devicesProvider.notifier).fetchDevices(mockEnvId);
      final device = container.read(deviceByIdProvider(mockEnvId, "dev_1001"));

      expect(device?.status, "online");
    });
  });
}


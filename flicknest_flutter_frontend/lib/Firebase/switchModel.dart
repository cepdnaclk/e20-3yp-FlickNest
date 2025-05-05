import 'package:firebase_database/firebase_database.dart';

class SwitchService {
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref("environments/env_12345/devices");
  final DatabaseReference _symbolsRef = FirebaseDatabase.instance.ref("symbols");

  Future<void> assignDeviceToRoom(String deviceId, String newRoomId) async {
    try {
      await _devicesRef.child(deviceId).update({"roomId": newRoomId});
      print("✅ Device $deviceId assigned to room $newRoomId");
    } catch (e) {
      print("❌ Error assigning device to room: $e");
    }
  }
  /// 🔥 Fetch devices grouped by room
  Stream<Map<String, dynamic>> getDevicesByRoomStream() {
    return _devicesRef.onValue.asyncMap((event) async {
      try {
        print("🟢 Fetching devices and rooms...");
        final devicesSnapshot = event.snapshot;
        final roomsRef = FirebaseDatabase.instance.ref("environments/env_12345/rooms");

        final roomsSnapshot = await roomsRef.get();
        if (!devicesSnapshot.exists || !roomsSnapshot.exists) {
          print("🟠 No devices or rooms found.");
          return {};
        }

        final devicesData = Map<String, dynamic>.from(devicesSnapshot.value as Map<dynamic, dynamic>);
        final roomsData = Map<String, dynamic>.from(roomsSnapshot.value as Map<dynamic, dynamic>);

        Map<String, dynamic> devicesByRoom = {};
        Map<String, dynamic> unassignedDevices = {};

        // Fetch room names from the rooms node
        final roomNames = <String, String>{};
        roomsData.forEach((roomId, roomInfo) {
          final room = Map<String, dynamic>.from(roomInfo);
          roomNames[roomId] = room["name"] as String? ?? "Unknown Room";
        });

        // Group devices by room
        devicesData.forEach((deviceId, deviceData) {
          final device = Map<String, dynamic>.from(deviceData as Map);
          final String? roomId = device["roomId"];
          final String? deviceName = device["name"];

          if (roomId != null && roomId.isNotEmpty && roomNames.containsKey(roomId)) {
            devicesByRoom.putIfAbsent(roomId, () => {"name": roomNames[roomId], "devices": <String, dynamic>{}});
            devicesByRoom[roomId]["devices"][deviceId] = device;
          } else {
            unassignedDevices[deviceId] = device;
          }
        });

        print("🟢 Devices by Room: $devicesByRoom");

        return {
          ...devicesByRoom,
          "unassigned": {"name": "Unassigned Devices", "devices": unassignedDevices}
        };
      } catch (e) {
        print("❌ Error fetching devices and rooms: $e");
        return {};
      }
    });
  }



  /// 🔥 Update device state (ON/OFF) and sync with assigned symbol
  Future<void> updateDeviceState(String deviceId, bool newState) async {
    try {
      final snapshot = await _devicesRef.child(deviceId).get();
      if (snapshot.exists) {
        final deviceData = Map<String, dynamic>.from(snapshot.value as Map);
        final String? assignedSymbol = deviceData["assignedSymbol"];

        if (assignedSymbol != null) {
          await _symbolsRef.child(assignedSymbol).update({"state": newState});
        }

        await _devicesRef.child(deviceId).update({"state": newState});
        print("✅ Device $deviceId state updated to: ${newState ? "ON" : "OFF"}");
      }
    } catch (e) {
      print("❌ Error updating device state: $e");
    }
  }

  // /// 🔥 Assign device to a room
  // Future<void> assignDeviceToRoom(String deviceId, String newRoomId) async {
  //   try {
  //     await _devicesRef.child(deviceId).update({"roomId": newRoomId});
  //     print("✅ Device $deviceId assigned to room $newRoomId");
  //   } catch (e) {
  //     print("❌ Error assigning device to room: $e");
  //   }
  // }

  /// 🔥 Remove device from a room (Moves to Unassigned)
  Future<void> removeDeviceFromRoom(String deviceId) async {
    try {
      await _devicesRef.child(deviceId).update({"roomId": ""});
      print("✅ Device $deviceId removed from its room (Unassigned)");
    } catch (e) {
      print("❌ Error removing device from room: $e");
    }
  }

  /// 🔥 Get available symbols for new devices
  Future<List<String>> getAvailableSymbols() async {
    try {
      final snapshot = await _symbolsRef.get();
      if (!snapshot.exists) {
        print("🟠 No symbols found.");
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<String> availableSymbols = [];

      data.forEach((symbolId, symbolData) {
        final symbol = Map<String, dynamic>.from(symbolData as Map);
        if (symbol["available"] == true) {
          availableSymbols.add(symbolId);
        }
      });

      return availableSymbols;
    } catch (e) {
      print("❌ Error fetching available symbols: $e");
      return [];
    }
  }

  /// 🔥 Add a new device
  Future<void> addDevice(String deviceName, String symbolId, String? roomId) async {
    try {
      final newDeviceRef = _devicesRef.push();
      final deviceId = newDeviceRef.key;

      if (deviceId != null) {
        await newDeviceRef.set({
          "name": deviceName,
          "roomId": roomId ?? "",
          "assignedSymbol": symbolId,
          "state": false,
          "allowedUsers": {},
        });

        await _symbolsRef.child(symbolId).update({"available": false});

        print("✅ Device $deviceId added with symbol $symbolId");
      }
    } catch (e) {
      print("❌ Error adding device: $e");
    }
  }
}

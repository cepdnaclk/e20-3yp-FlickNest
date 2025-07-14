import 'package:firebase_database/firebase_database.dart';

class DeviceService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all available symbols with their names
  Future<List<Map<String, String>>> getAvailableSymbolsWithNames() async {
    final symbolsWithNames = <Map<String, String>>[];
    
    try {
      final symbolsSnapshot = await _database.child('symbols').get();
      
      if (symbolsSnapshot.exists && symbolsSnapshot.value is Map) {
        final symbols = Map<String, dynamic>.from(symbolsSnapshot.value as Map);
        
        await Future.wait(symbols.entries.map((entry) async {
          final symbolId = entry.key;
          final availableSnapshot = await _database.child('symbols/$symbolId/available').get();
          final nameSnapshot = await _database.child('symbols/$symbolId/name').get();
          
          if (availableSnapshot.exists && availableSnapshot.value == true) {
            final name = nameSnapshot.exists ? nameSnapshot.value.toString() : symbolId;
            symbolsWithNames.add({
              'id': symbolId.toString(),
              'name': name,
            });
          }
        }));
      }
    } catch (e) {
      print('Error fetching symbols with names: $e');
      rethrow;
    }
    
    return symbolsWithNames;
  }

  /// Get symbol name by ID (used for display in other parts of the app)
  Future<String> getSymbolName(String symbolId) async {
    try {
      final snapshot = await _database.child('symbols/$symbolId/name').get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
      return symbolId; // Return symbol ID if name not found
    } catch (e) {
      print('Error fetching symbol name: $e');
      return symbolId; // Return symbol ID on error
    }
  }

  /// Get used symbols (needed for device management)
  Future<List<String>> getUsedSymbols() async {
    try {
      final snapshot = await _database.child('devices').get();
      if (snapshot.exists && snapshot.value is Map) {
        final devices = Map<String, dynamic>.from(snapshot.value as Map);
        final usedSymbols = devices.values
            .where((device) => device is Map && device['assignedSymbol'] != null)
            .map((device) => device['assignedSymbol'].toString())
            .toList();
        return usedSymbols;
      }
      return [];
    } catch (e) {
      print('Error getting used symbols: $e');
      return [];
    }
  }

  /// Add a new device
  Future<void> addDevice(String name, String symbolId, String? roomId, {required String environmentId}) async {
    try {
      // Generate a unique device ID based on the symbol ID
      final deviceId = 'dev_${symbolId.replaceAll('sym_', '')}';
      
      // Create the device data
      final deviceData = {
        'name': name,
        'assignedSymbol': symbolId,
        'state': false,
        'environmentId': environmentId,
      };

      // Add to room if specified
      if (roomId != null) {
        await _database.child('rooms/$roomId/devices/$deviceId').set(deviceData);
      } else {
        await _database.child('unassigned/devices/$deviceId').set(deviceData);
      }

    } catch (e) {
      print('Error adding device: $e');
      rethrow;
    }
  }

  /// Update device room
  Future<void> updateDeviceRoom(String deviceId, String? newRoomId) async {
    try {
      // First, get the device data from all possible locations
      DataSnapshot? deviceSnapshot;
      
      // Check unassigned devices
      deviceSnapshot = await _database.child('unassigned/devices/$deviceId').get();
      
      // If not found in unassigned, check all rooms
      if (!deviceSnapshot.exists) {
        final roomsSnapshot = await _database.child('rooms').get();
        if (roomsSnapshot.exists && roomsSnapshot.value is Map) {
          final rooms = Map<String, dynamic>.from(roomsSnapshot.value as Map);
          for (var roomData in rooms.entries) {
            if (roomData.value is Map && 
                (roomData.value as Map).containsKey('devices') &&
                (roomData.value['devices'] as Map).containsKey(deviceId)) {
              deviceSnapshot = await _database.child('rooms/${roomData.key}/devices/$deviceId').get();
              // Remove from old room
              await _database.child('rooms/${roomData.key}/devices/$deviceId').remove();
              break;
            }
          }
        }
      } else {
        // Remove from unassigned
        await _database.child('unassigned/devices/$deviceId').remove();
      }

      if (deviceSnapshot != null && deviceSnapshot.exists) {
        final deviceData = Map<String, dynamic>.from(deviceSnapshot.value as Map);
        
        // Add to new location
        if (newRoomId != null) {
          await _database.child('rooms/$newRoomId/devices/$deviceId').set(deviceData);
        } else {
          await _database.child('unassigned/devices/$deviceId').set(deviceData);
        }
      }
    } catch (e) {
      print('Error updating device room: $e');
      rethrow;
    }
  }

  /// Update symbol source
  Future<void> updateSymbolSource(String symbolId, String source) async {
    try {
      await _database.child('symbols/$symbolId/source').set(source);
    } catch (e) {
      print('Error updating symbol source: $e');
      rethrow;
    }
  }

  /// Remove a device and mark its symbol as available
  Future<void> removeDevice(String deviceId, String symbolId) async {
    try {
      // First, get the device data from all possible locations
      DataSnapshot? deviceSnapshot;
      
      // Check unassigned devices
      deviceSnapshot = await _database.child('unassigned/devices/$deviceId').get();
      
      // If not found in unassigned, check all rooms
      if (!deviceSnapshot.exists) {
        final roomsSnapshot = await _database.child('rooms').get();
        if (roomsSnapshot.exists && roomsSnapshot.value is Map) {
          final rooms = Map<String, dynamic>.from(roomsSnapshot.value as Map);
          for (var roomData in rooms.entries) {
            if (roomData.value is Map && 
                (roomData.value as Map).containsKey('devices') &&
                (roomData.value['devices'] as Map).containsKey(deviceId)) {
              // Remove from room
              await _database.child('rooms/${roomData.key}/devices/$deviceId').remove();
              break;
            }
          }
        }
      } else {
        // Remove from unassigned
        await _database.child('unassigned/devices/$deviceId').remove();
      }

      // Mark symbol as available again
      await _database.child('symbols/$symbolId/available').set(true);
    } catch (e) {
      print('Error removing device: $e');
      rethrow;
    }
  }
}
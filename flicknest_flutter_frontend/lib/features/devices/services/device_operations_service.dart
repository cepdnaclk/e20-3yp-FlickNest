import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/local_broker_service.dart';
import '../../../constants.dart';

class DeviceOperationsService {
  final String? environmentId;
  final LocalBrokerService _localBrokerService = LocalBrokerService.instance;

  DeviceOperationsService(this.environmentId);

  Future<void> updateDeviceState(String deviceId, String symbolKey, bool newState, bool isLocal) async {
    try {
      if (isLocal) {
        // In local mode, only update the local broker
        await _updateLocalDeviceState(deviceId, symbolKey, newState);
      } else {
        // In online mode, update Firebase
        await _updateFirebaseDeviceState(deviceId, symbolKey, newState);
      }
    } catch (e) {
      print('🔴 Device state update failed: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalDeviceState(String deviceId, String symbolKey, bool state) async {
    try {
      // Update local broker
      await _localBrokerService.updateSymbolState(symbolKey, state);

      // Store the state change for later sync
      if (environmentId != null) {
        final prefs = await SharedPreferences.getInstance();
        final localStatesStr = prefs.getString('local_device_states_$environmentId');
        Map<String, dynamic> localStates = {};

        if (localStatesStr != null) {
          localStates = json.decode(localStatesStr);
        }

        localStates[deviceId] = state;
        await prefs.setString('local_device_states_$environmentId', json.encode(localStates));
      }
    } catch (e) {
      print('🔴 Local state update failed: $e');
      rethrow;
    }
  }

  Future<void> _syncSymbolState(String symbolId, bool newState) async {
    try {
      final symbolRef = FirebaseDatabase.instance.ref('symbols/$symbolId');
      await symbolRef.update({
        'state': newState,
        'source': AppConstants.deviceSourceMobile
      });
      print('📱 Symbol $symbolId state updated to: $newState');
    } catch (e) {
      print('🔴 Error updating symbol state: $e');
      rethrow;
    }
  }

  Future<void> _updateFirebaseDeviceState(
    String deviceId,
    String symbolKey,
    bool newState,
    {bool silent = false}
  ) async {
    if (environmentId == null) throw Exception('Environment ID is required for Firebase operations');

    try {
      final deviceRef = FirebaseDatabase.instance
          .ref('environments/$environmentId/devices/$deviceId');

      // Update device state
      await deviceRef.update({'state': newState});

      if (!silent) {
        // Update symbol state to match device state
        await _syncSymbolState(symbolKey, newState);
      }
    } catch (e) {
      print('🔴 Firebase state update failed: $e');
      rethrow;
    }
  }

  StreamSubscription<DatabaseEvent> listenToSymbolStateChanges(
    Function(String, bool) onSymbolStateChanged
  ) {
    return FirebaseDatabase.instance.ref('symbols').onChildChanged.listen((event) async {
      final symbolId = event.snapshot.key;
      final symbolData = event.snapshot.value as Map?;
      if (symbolId == null || symbolData == null) return;
      if (!symbolData.containsKey('state')) return;

      final bool symbolState = symbolData['state'];
      onSymbolStateChanged(symbolId, symbolState);

      // Update all devices using this symbol
      if (environmentId != null) {
        try {
          final devicesRef = FirebaseDatabase.instance.ref('environments/$environmentId/devices');
          final snapshot = await devicesRef.get();

          if (snapshot.exists) {
            final devices = Map<String, dynamic>.from(snapshot.value as Map);

            // Find and update all devices assigned to this symbol
            for (final entry in devices.entries) {
              final deviceId = entry.key;
              final deviceData = Map<String, dynamic>.from(entry.value as Map);

              if (deviceData['assignedSymbol'] == symbolId) {
                // Update device state to match symbol state
                await devicesRef.child(deviceId).update({
                  'state': symbolState
                });
              }
            }
          }
        } catch (e) {
          print('🔴 Error syncing devices with symbol state: $e');
        }
      }
    });
  }

  Future<void> syncLocalChangesToFirebase() async {
    if (environmentId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_states_$environmentId';
      final storedStates = prefs.getString(key);

      if (storedStates != null) {
        final states = Map<String, dynamic>.from(json.decode(storedStates));
        final dbRef = FirebaseDatabase.instance.ref('environments/$environmentId/devices');

        for (final entry in states.entries) {
          final deviceId = entry.key;
          final deviceData = entry.value as Map<String, dynamic>;
          final bool state = deviceData['state'];
          final String symbolKey = deviceData['symbolKey'];

          // Update both device and symbol states
          await Future.wait([
            dbRef.child(deviceId).update({'state': state}),
            _syncSymbolState(symbolKey, state),
          ]);
        }

        // Clear local states after successful sync
        await prefs.remove(key);
      }
    } catch (e) {
      print('🔴 Error syncing to Firebase: $e');
      rethrow;
    }
  }

  Future<void> moveDeviceToRoom(String deviceId, String? targetRoomId) async {
    if (environmentId == null) throw Exception('Environment ID is required');

    try {
      final deviceRef = FirebaseDatabase.instance
          .ref('environments/$environmentId/devices/$deviceId');
      await deviceRef.update({'roomId': targetRoomId ?? 'unassigned'});

      print('📱 Device $deviceId moved to room $targetRoomId');
    } catch (e) {
      print('🔴 Error moving device: $e');
      rethrow;
    }
  }

  Future<void> addDevice(String deviceName, String symbolId, String? roomId) async {
    if (environmentId == null) throw Exception('Environment ID is required');

    try {
      final deviceRef = FirebaseDatabase.instance.ref('environments/$environmentId/devices');
      final newDeviceKey = deviceRef.push().key;
      if (newDeviceKey == null) throw Exception('Failed to generate device key');

      // Mark the symbol as not available
      final symbolRef = FirebaseDatabase.instance.ref('symbols/$symbolId');
      await symbolRef.update({'available': false});

      // Create the new device
      await deviceRef.child(newDeviceKey).set({
        'name': deviceName,
        'assignedSymbol': symbolId,
        'roomId': roomId ?? 'unassigned',
        'state': false,
      });

      // If room is specified, add device to room's devices list
      if (roomId != null) {
        final roomRef = FirebaseDatabase.instance
            .ref('environments/$environmentId/rooms/$roomId/devices');
        await roomRef.child(newDeviceKey).set(true);
      }

      print('📱 Added new device: $deviceName with symbol: $symbolId to room: $roomId');
    } catch (e) {
      print('🔴 Error adding device: $e');
      rethrow;
    }
  }
}

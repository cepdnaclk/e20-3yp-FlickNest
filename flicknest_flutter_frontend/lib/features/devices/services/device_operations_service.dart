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
      await deviceRef.update({'state': newState});

      if (!silent) {
        final symbolRef = FirebaseDatabase.instance.ref('symbols/$symbolKey');
        await symbolRef.update({
          'state': newState,
          'source': AppConstants.deviceSourceMobile
        });
      }
    } catch (e) {
      print('🔴 Firebase state update failed: $e');
      rethrow;
    }
  }

  Future<void> moveDeviceToRoom(String deviceId, String? targetRoomId) async {
    if (environmentId == null) throw Exception('Environment ID is required');

    try {
      final deviceRef = FirebaseDatabase.instance
          .ref('environments/$environmentId/devices/$deviceId');
      await deviceRef.update({'roomId': targetRoomId ?? 'unassigned'});
    } catch (e) {
      throw Exception('Error moving device: $e');
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
    } catch (e) {
      throw Exception('Error adding device: $e');
    }
  }

  Future<void> syncLocalChangesWithFirebase() async {
    if (environmentId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localDeviceStates = prefs.getString('local_device_states_$environmentId');

      if (localDeviceStates != null) {
        final Map<String, dynamic> states = json.decode(localDeviceStates);
        final dbRef = FirebaseDatabase.instance.ref('environments/$environmentId/devices');

        // Get current Firebase states
        final snapshot = await dbRef.get();
        if (!snapshot.exists) return;

        final firebaseDevices = Map<String, dynamic>.from(snapshot.value as Map);

        // Update Firebase with local states
        for (final entry in states.entries) {
          final deviceId = entry.key;
          final bool localState = entry.value;

          if (firebaseDevices.containsKey(deviceId)) {
            await dbRef.child(deviceId).update({'state': localState});
          }
        }

        // Clear local states after successful sync
        await prefs.remove('local_device_states_$environmentId');
      }
    } catch (e) {
      print('Error syncing local changes with Firebase: $e');
      rethrow;
    }
  }

  StreamSubscription<DatabaseEvent> listenToSymbolStateChanges(
    Function(String, bool) onSymbolStateChanged
  ) {
    return FirebaseDatabase.instance.ref('symbols').onChildChanged.listen((event) {
      final symbolId = event.snapshot.key;
      final symbolData = event.snapshot.value as Map?;
      if (symbolId == null || symbolData == null) return;
      if (!symbolData.containsKey('state')) return;

      onSymbolStateChanged(symbolId, symbolData['state'] as bool);
    });
  }
}

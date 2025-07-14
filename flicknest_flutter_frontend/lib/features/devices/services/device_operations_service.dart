import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
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
        await _updateLocalDeviceState(symbolKey, newState);
      } else {
        // In online mode, update Firebase
        await _updateFirebaseDeviceState(deviceId, symbolKey, newState);
      }
    } catch (e) {
      print('🔴 Device state update failed: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalDeviceState(String symbolKey, bool state) async {
    try {
      await _localBrokerService.updateSymbolState(symbolKey, state);
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

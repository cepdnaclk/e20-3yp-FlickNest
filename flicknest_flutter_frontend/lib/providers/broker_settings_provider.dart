import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import '../services/local_broker_service.dart';
import '../services/local_websocket_service.dart';

final brokerSettingsProvider = StateNotifierProvider<BrokerSettingsNotifier, bool>((ref) {
  return BrokerSettingsNotifier();
});

class BrokerSettingsNotifier extends StateNotifier<bool> {
  static const String _key = 'useLocalBroker';
  final FirebaseDatabase _firebaseDb = FirebaseDatabase.instance;
  final LocalWebSocketService _webSocketService = LocalWebSocketService();

  BrokerSettingsNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    if (state) {
      await _firebaseDb.goOffline();
      _webSocketService.connect();
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      // Get current local state
      final localBrokerService = LocalBrokerService();
      final symbols = await localBrokerService.getAllSymbols();

      if (symbols != null) {
        print('Syncing local changes to Firebase...');
        // Update Firebase with local data
        for (var entry in symbols.entries) {
          final symbolId = entry.key;
          final symbolData = entry.value;
          await _firebaseDb.ref('symbols/$symbolId').update(symbolData);
          print('Synced symbol $symbolId to Firebase');
        }
        print('Successfully synced all local changes to Firebase');
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
      throw e;
    }
  }

  Future<void> toggleBrokerMode() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (state) {
        // Switching from local to online
        print('Switching from local to online mode...');
        // First sync all local changes to Firebase
        await _syncToFirebase();
        // Then disconnect local connections
        _webSocketService.disconnect();
        // Finally enable Firebase
        await _firebaseDb.goOnline();
      } else {
        // Switching from online to local
        print('Switching from online to local mode...');
        await _firebaseDb.goOffline();
        _webSocketService.connect();
      }

      // Update state after successful switch
      state = !state;
      await prefs.setBool(_key, state);
      print('Successfully switched to ${state ? "local" : "online"} mode');

    } catch (e) {
      print('Error switching modes: $e');
      throw Exception('Failed to switch network mode: $e');
    }
  }

  Future<dynamic> fetchData(String entity) async {
    if (state) {
      // Local mode: fetch via WebSocket
      final completer = Completer();
      _webSocketService.requestAll(entity, (data) {
        completer.complete(data);
      });
      return completer.future;
    } else {
      // Online mode: fetch from Firebase
      final ref = _firebaseDb.ref(entity);
      final snapshot = await ref.get();
      return snapshot.value;
    }
  }

  Future<void> saveData(String entity, String id, dynamic data) async {
    if (state) {
      // Local mode: update via WebSocket only
      _webSocketService.updateEntity(entity, id, data);
    } else {
      // Online mode: update Firebase only
      final ref = _firebaseDb.ref('$entity/$id');
      await ref.set(data);
    }
  }

  void listenUpdates(Function(dynamic) onUpdate) {
    _webSocketService.listenUpdates(onUpdate);
  }
}

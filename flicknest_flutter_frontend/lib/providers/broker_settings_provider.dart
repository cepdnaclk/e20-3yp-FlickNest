import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import '../services/local_websocket_service.dart';

final brokerSettingsProvider = StateNotifierProvider<BrokerSettingsNotifier, bool>((ref) {
  return BrokerSettingsNotifier();
});

class BrokerSettingsNotifier extends StateNotifier<bool> {
  static const String _key = 'useLocalBroker';
  static const String _localDbPath = 'local_db.json';
  final FirebaseDatabase _firebaseDb = FirebaseDatabase.instance;
  final LocalWebSocketService _webSocketService = LocalWebSocketService();

  BrokerSettingsNotifier() : super(false) {
    _loadPreference();
    _webSocketService.connect();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggleBrokerMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(_key, state);
    await _handleBrokerModeChange();
  }

  Future<void> _handleBrokerModeChange() async {
    if (state) {
      // Switch to local broker mode
      await _firebaseDb.goOffline();
      // No need to set local URL or interact with Firebase
    } else {
      // Switch to online Firebase mode
      await _firebaseDb.goOnline();
      // Use default Firebase URL
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
      // Local mode: update via WebSocket
      _webSocketService.updateEntity(entity, id, data);
    } else {
      // Online mode: update both Firebase and local
      final ref = _firebaseDb.ref('$entity/$id');
      await ref.set(data);
      _webSocketService.updateEntity(entity, id, data);
    }
  }

  void listenUpdates(Function(dynamic) onUpdate) {
    _webSocketService.listenUpdates(onUpdate);
  }
}

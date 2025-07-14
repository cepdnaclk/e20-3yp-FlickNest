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
      // If starting in local mode, disconnect from Firebase
      await _firebaseDb.goOffline();
      _webSocketService.connect();
    }
  }

  Future<void> toggleBrokerMode() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (state) {
        // Switching from local to online
        print('Switching to online mode...');
        // First disconnect local connections
        _webSocketService.disconnect();
        // Enable Firebase
        await _firebaseDb.goOnline();
      } else {
        // Switching from online to local
        print('Switching to local mode...');
        // Disconnect from Firebase first
        await _firebaseDb.goOffline();
        // Then connect to local broker
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

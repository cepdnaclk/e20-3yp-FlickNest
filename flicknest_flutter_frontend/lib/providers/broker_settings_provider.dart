import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';

final brokerSettingsProvider = StateNotifierProvider<BrokerSettingsNotifier, bool>((ref) {
  return BrokerSettingsNotifier();
});

class BrokerSettingsNotifier extends StateNotifier<bool> {
  static const String _key = 'useLocalBroker';
  static const String _localDbPath = 'local_db.json';
  final FirebaseDatabase _firebaseDb = FirebaseDatabase.instance;

  BrokerSettingsNotifier() : super(false) {
    _loadPreference();
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

  Future<dynamic> fetchData(String path) async {
    try {
      if (state) {
        // Local broker fetch logic (local JSON file)
        return await _fetchFromLocalBroker(path);
      } else {
        // Firebase fetch logic
        final ref = _firebaseDb.ref(path);
        final snapshot = await ref.get();
        return snapshot.value;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> _fetchFromLocalBroker(String path) async {
    final file = File(_localDbPath);
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    final Map<String, dynamic> db = json.decode(contents);
    return db[path];
  }

  Future<void> saveData(String path, dynamic data) async {
    try {
      if (state) {
        // Local broker save logic (local JSON file)
        await _saveToLocalBroker(path, data);
      } else {
        // Firebase save logic
        final ref = _firebaseDb.ref(path);
        await ref.set(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveToLocalBroker(String path, dynamic data) async {
    final file = File(_localDbPath);
    Map<String, dynamic> db = {};
    if (await file.exists()) {
      final contents = await file.readAsString();
      db = json.decode(contents);
    }
    db[path] = data;
    await file.writeAsString(json.encode(db));
  }
}

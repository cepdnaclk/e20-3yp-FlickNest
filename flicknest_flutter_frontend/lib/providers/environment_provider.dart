import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to store the current environment ID
final currentEnvironmentProvider = StateNotifierProvider<EnvironmentNotifier, String?>((ref) {
  return EnvironmentNotifier();
});

// Provider to fetch environment details
final environmentDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, envId) async {
  if (envId.isEmpty) return null;
  
  final snapshot = await FirebaseDatabase.instance
      .ref('environments/$envId')
      .get();
      
  if (!snapshot.exists) return null;
  
  final data = snapshot.value;
  if (data == null) return null;
  
  // Properly handle the type casting by recursively converting all nested maps
  Map<String, dynamic> convertMap(Map<Object?, Object?> map) {
    return map.map((key, value) {
      if (value is Map<Object?, Object?>) {
        return MapEntry(key.toString(), convertMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), value.map((e) => e is Map<Object?, Object?> ? convertMap(e) : e).toList());
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
  
  return convertMap(data as Map<Object?, Object?>);
});

// Provider to fetch user's environments
final userEnvironmentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final userEnvsSnapshot = await FirebaseDatabase.instance
      .ref('users/${user.uid}/environments')
      .get();
      
  if (!userEnvsSnapshot.exists) return {};

  final userEnvIds = Map<String, dynamic>.from(userEnvsSnapshot.value as Map);
  final Map<String, dynamic> environments = {};

  await Future.wait(
    userEnvIds.entries.map((entry) async {
      final envId = entry.key;
      final envSnapshot = await FirebaseDatabase.instance
          .ref('environments/$envId')
          .get();
          
      if (envSnapshot.exists) {
        environments[envId] = Map<String, dynamic>.from(envSnapshot.value as Map);
      }
    })
  );

  return environments;
});

class EnvironmentNotifier extends StateNotifier<String?> {
  EnvironmentNotifier() : super(null) {
    _initializeEnvironment();
  }

  Future<void> _initializeEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnvId = prefs.getString('current_environment');
    if (savedEnvId != null) {
      state = savedEnvId;
    }
  }

  Future<void> setEnvironment(String environmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_environment', environmentId);
    state = environmentId;
  }

  Future<void> clearEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_environment');
    state = null;
  }
} 
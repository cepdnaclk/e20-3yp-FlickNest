import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

/// Notifier class to manage the current environment state
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

/// Provider to store the current environment ID
/// 
/// This provider manages the currently selected environment and persists
/// the selection in SharedPreferences.
final currentEnvironmentProvider = StateNotifierProvider<EnvironmentNotifier, String?>((ref) {
  return EnvironmentNotifier();
});

/// Provider to fetch environment details
/// 
/// This provider fetches the details of a specific environment from Firebase.
/// Returns null if the environment doesn't exist or if the ID is empty.
final environmentDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, envId) async {
  if (envId.isEmpty) return null;
  
  final snapshot = await FirebaseDatabase.instance
      .ref('environments/$envId')
      .get();
      
  if (!snapshot.exists) return null;
  
  final data = snapshot.value;
  if (data == null) return null;
  
  return _convertFirebaseMap(data as Map<Object?, Object?>);
});

/// Provider to fetch user's environments
/// 
/// This provider fetches all environments that the current user has access to.
/// Returns an empty map if the user is not authenticated or has no environments.
final userEnvironmentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentAuthUserProvider).value;
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

/// Helper function to convert Firebase map to the correct type
Map<String, dynamic> _convertFirebaseMap(Map<Object?, Object?> map) {
  return map.map((key, value) {
    if (value is Map<Object?, Object?>) {
      return MapEntry(key.toString(), _convertFirebaseMap(value));
    } else if (value is List) {
      return MapEntry(key.toString(), value.map((e) => e is Map<Object?, Object?> ? _convertFirebaseMap(e) : e).toList());
    } else {
      return MapEntry(key.toString(), value);
    }
  });
} 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_provider.dart';
import '../environment/environment_provider.dart';

/// Provider to get the current user's role in the current environment
/// 
/// This provider checks both possible locations for role information:
/// 1. environments/{environmentID}/users/{userID}/role
/// 2. users/{userID}/environments/{environmentID}
/// 
/// Returns null if:
/// - No user is authenticated
/// - No environment is selected
/// - User has no access to the selected environment
final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentAuthUserProvider).value;
  final environmentId = ref.watch(currentEnvironmentProvider);
  
  if (user == null || environmentId == null) return null;

  try {
    // Try to get role from environments/{environmentID}/users/{userID}/role
    final envUserRef = FirebaseDatabase.instance
        .ref('environments/$environmentId/users/${user.uid}/role');
    final envUserSnapshot = await envUserRef.get();
    
    if (envUserSnapshot.exists) {
      return envUserSnapshot.value as String?;
    }

    // If not found, try users/{userID}/environments/{environmentID}
    final userEnvRef = FirebaseDatabase.instance
        .ref('users/${user.uid}/environments/$environmentId');
    final userEnvSnapshot = await userEnvRef.get();
    
    if (userEnvSnapshot.exists) {
      return userEnvSnapshot.value as String?;
    }

    return null;
  } catch (e) {
    print('Error fetching user role: $e');
    return null;
  }
});

/// Provider to check if the current user has admin access
final isAdminProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(currentUserRoleProvider);
  return roleAsync.value == 'admin';
});

/// Provider to check if the current user has co-admin access
final isCoAdminProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(currentUserRoleProvider);
  return roleAsync.value == 'co-admin';
});

/// Provider to check if the current user has basic user access
final isUserProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(currentUserRoleProvider);
  return roleAsync.value == 'user';
}); 
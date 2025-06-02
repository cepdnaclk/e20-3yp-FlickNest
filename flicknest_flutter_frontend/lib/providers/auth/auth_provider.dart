import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a stream of the current authenticated user
/// 
/// This provider will automatically update whenever the authentication state changes.
/// Returns null when no user is authenticated.
final currentAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides the current user's ID
/// 
/// This is a convenience provider that extracts the user ID from [currentAuthUserProvider].
/// Returns an empty string when no user is authenticated.
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentAuthUserProvider).value?.uid ?? '';
});

/// Provides the current user's email
/// 
/// This is a convenience provider that extracts the email from [currentAuthUserProvider].
/// Returns null when no user is authenticated or when the user has no email.
final currentUserEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentAuthUserProvider).value?.email;
}); 
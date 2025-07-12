import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../features/landing/presentation/pages/home.page.dart';
import '../helpers/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class GoogleSignInResult {
  final UserCredential userCredential;
  final String idToken;
  GoogleSignInResult({required this.userCredential, required this.idToken});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In aborted by user');
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Sign in was canceled by the user'
        );
      }

      print('Google Sign In successful for user: ${googleUser.email}');

      // Obtain the auth details from the request
      print('Obtaining Google auth details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        print('Error: Google Auth accessToken is null');
        throw FirebaseAuthException(
          code: 'invalid_token',
          message: 'Failed to obtain access token'
        );
      }

      if (googleAuth.idToken == null) {
        print('Error: Google Auth idToken is null');
        throw FirebaseAuthException(
          code: 'invalid_token',
          message: 'Failed to obtain ID token'
        );
      }

      // Create a new credential
      print('Creating credentials...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      print('Signing in to Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print('Firebase sign in successful');

      // Add user to Realtime Database if first login
      final user = userCredential.user;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await dbRef.get();
        if (!snapshot.exists) {
          await dbRef.set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': DateTime.now().toIso8601String(),
          });
          print('User added to Realtime Database');
        } else {
          print('User already exists in Realtime Database');
        }
      }

      return GoogleSignInResult(
        userCredential: userCredential,
        idToken: googleAuth.idToken!,
      );

    } catch (e) {
      print('Error in signInWithGoogle: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'sign_in_failed',
        message: 'Sign in failed: ${e.toString()}'
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      await _googleSignIn.signOut();
      print('Successfully signed out from Google');
      await _auth.signOut();
      print('Successfully signed out from Firebase');
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }
}


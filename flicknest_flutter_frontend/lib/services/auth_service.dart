import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../features/landing/presentation/pages/home.page.dart';
import '../helpers/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In aborted by user');
        return null;
      }

      print('Google Sign In successful for user: ${googleUser.email}');

      try {
        // Obtain the auth details from the request
        print('Obtaining Google auth details...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (googleAuth.accessToken == null) {
          print('Error: Google Auth accessToken is null');
          return null;
        }
        
        if (googleAuth.idToken == null) {
          print('Error: Google Auth idToken is null');
          return null;
        }

        print('Successfully obtained Google auth tokens');

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Created Firebase credential from Google auth tokens');

        // Sign in to Firebase with the Google credential
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          print('Successfully signed in to Firebase with Google credential');
          print('User ID: ${userCredential.user?.uid}');
          print('User Email: ${userCredential.user?.email}');
          
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
          
          return userCredential;
        } on FirebaseAuthException catch (e) {
          print('Firebase Auth Exception during credential sign in:');
          print('Error code: ${e.code}');
          print('Error message: ${e.message}');
          print('Error details: ${e.toString()}');
          rethrow;
        }
      } on Exception catch (e) {
        print('Error getting Google auth tokens:');
        print(e.toString());
        rethrow;
      }
    } on Exception catch (e) {
      print('General error during Google Sign In:');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      rethrow;
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
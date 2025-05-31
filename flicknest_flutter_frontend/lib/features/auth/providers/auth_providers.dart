// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
//   return FirebaseAuth.instance;
// });
//
// final googleSignInProvider = Provider<GoogleSignIn>((ref) {
//   return GoogleSignIn();
// });
//
// final authStateProvider = StreamProvider<User?>((ref) {
//   return ref.watch(firebaseAuthProvider).authStateChanges();
// });
//
// class AuthRepository {
//   final FirebaseAuth _firebaseAuth;
//   final GoogleSignIn _googleSignIn;
//
//   AuthRepository(this._firebaseAuth, this._googleSignIn);
//
//   Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
//
//   Future<User?> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return null;
//
//       final GoogleSignInAuthentication googleAuth =
//       await googleUser.authentication;
//
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final UserCredential userCredential =
//       await _firebaseAuth.signInWithCredential(credential);
//       return userCredential.user;
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<User?> signInWithEmailAndPassword(
//       String email, String password) async {
//     try {
//       final UserCredential userCredential =
//       await _firebaseAuth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<User?> registerWithEmailAndPassword(
//       String email, String password) async {
//     try {
//       final UserCredential userCredential =
//       await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _firebaseAuth.signOut();
//   }
// }
//
// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return AuthRepository(
//     ref.watch(firebaseAuthProvider),
//     ref.watch(googleSignInProvider),
//   );
// });
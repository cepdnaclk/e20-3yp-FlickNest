import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flicknest_flutter_frontend/services/auth_service.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  User,
  DatabaseReference,
  DataSnapshot,
])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    // Set up default mock behavior
    when(mockGoogleSignInAuthentication.accessToken).thenReturn('fake-access-token');
    when(mockGoogleSignInAuthentication.idToken).thenReturn('fake-id-token');
    when(mockGoogleSignInAccount.authentication)
        .thenAnswer((_) async => mockGoogleSignInAuthentication);
    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-uid');
    when(mockUser.email).thenReturn('test@example.com');

    authService = AuthService();
  });

  group('AuthService', () {
    test('currentUser should return the current Firebase user', () {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      expect(authService.currentUser, mockUser);
    });

    test('authStateChanges should return the Firebase auth state stream', () {
      final Stream<User?> stream = Stream.value(mockUser);
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => stream);
      expect(authService.authStateChanges, emits(mockUser));
    });

    group('signInWithGoogle', () {
      test('successful sign in should return UserCredential', () async {
        when(mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleSignInAccount);
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);

        final result = await authService.signInWithGoogle();
        expect(result, equals(mockUserCredential));
      });

      test('should handle null GoogleSignInAccount', () async {
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await authService.signInWithGoogle();
        expect(result, isNull);
      });

      test('should handle FirebaseAuthException', () async {
        when(mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleSignInAccount);
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('successful sign out should complete without errors', () async {
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

        await expectLater(
          authService.signOut(),
          completes,
        );
      });

      test('should handle sign out errors', () async {
        when(mockGoogleSignIn.signOut())
            .thenThrow(Exception('Sign out failed'));

        expect(
          () => authService.signOut(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
} 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

// Firebase Auth Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid';
  @override
  String? get email => 'test@example.com';
}

// Firebase Database Mocks
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

class TestUtils {
  // Auth Utilities
  static MockFirebaseAuth getMockAuth() {
    return MockFirebaseAuth();
  }

  static MockUser getMockUser() {
    return MockUser();
  }

  // Database Utilities
  static MockFirebaseDatabase getMockDatabase() {
    return MockFirebaseDatabase();
  }

  static void setupMockDatabaseResponse(MockFirebaseDatabase mockDb, Map<String, dynamic>? data) {
    final mockRef = MockDatabaseReference();
    final mockSnapshot = MockDataSnapshot();

    when(mockDb.ref(any)).thenReturn(mockRef);
    when(mockRef.get()).thenAnswer((_) async => mockSnapshot);
    when(mockSnapshot.value).thenReturn(data);
  }

  static void setupMockAuthState(MockFirebaseAuth auth, {bool isLoggedIn = false}) {
    final mockUser = isLoggedIn ? MockUser() : null;
    when(auth.currentUser).thenReturn(mockUser);
    when(auth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
  }

  static void setupMockUserRole(MockFirebaseAuth mockAuth, String role) {
    final mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-uid');
    when(mockUser.email).thenReturn('test@example.com');
    // Simulate role assignment logic if needed.
  }
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Integration Tests', () {
    late FirebaseDatabase database;
    late ProviderContainer container;
    final testEnvId = 'test-environment-${DateTime.now().millisecondsSinceEpoch}';

    setUpAll(() async {
      await Firebase.initializeApp();
      database = FirebaseDatabase.instance;
      container = ProviderContainer();
    });

    test('can create new environment', () async {
      final ref = database.ref('environments/$testEnvId');
      await ref.set({
        'name': 'Test Environment',
        'created_at': ServerValue.timestamp,
      });

      final snapshot = await ref.get();
      expect(snapshot.exists, isTrue);
      expect((snapshot.value as Map)['name'], equals('Test Environment'));
    });

    test('can add device to environment', () async {
      final deviceRef = database.ref('environments/$testEnvId/devices/device1');
      await deviceRef.set({
        'name': 'Test Device',
        'type': 'sensor',
        'status': 'active',
      });

      final snapshot = await deviceRef.get();
      expect(snapshot.exists, isTrue);
      expect((snapshot.value as Map)['name'], equals('Test Device'));
    });

    test('can add room to environment', () async {
      final roomRef = database.ref('environments/$testEnvId/rooms/room1');
      await roomRef.set({
        'name': 'Test Room',
        'type': 'bedroom',
      });

      final snapshot = await roomRef.get();
      expect(snapshot.exists, isTrue);
      expect((snapshot.value as Map)['name'], equals('Test Room'));
    });

    test('can update device status', () async {
      final deviceRef = database.ref('environments/$testEnvId/devices/device1');
      await deviceRef.update({
        'status': 'inactive',
      });

      final snapshot = await deviceRef.get();
      expect((snapshot.value as Map)['status'], equals('inactive'));
    });

    test('can listen to real-time updates', () async {
      final completer = Completer<DatabaseEvent>();
      final ref = database.ref('environments/$testEnvId');
      
      ref.onValue.listen((event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      await ref.update({'last_updated': ServerValue.timestamp});
      final event = await completer.future;
      
      expect(event.snapshot.exists, isTrue);
    });

    tearDownAll(() async {
      // Clean up test data
      await database.ref('environments/$testEnvId').remove();
    });
  });
} 
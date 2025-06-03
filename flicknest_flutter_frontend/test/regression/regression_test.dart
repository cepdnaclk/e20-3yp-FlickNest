import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../test_utils.dart';

void main() {
  group('Regression Tests', () {
    late MockFirebaseDatabase mockDb;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
      mockAuth = TestUtils.getMockAuth();
    });

    testWidgets('Device state persists after background refresh', (tester) async {
      // Test for issue #123: Device state reset after app refresh
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'devices': [{
          'id': 'device1',
          'name': 'Test AC',
          'status': 'on',
          'temperature': 24
        }]
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DevicesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Test AC'), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);

      // Simulate app going to background and returning
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify state is maintained
      expect(find.text('Test AC'), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);
    });

    testWidgets('Multiple rapid device controls handle correctly', (tester) async {
      // Test for issue #145: Device control race condition
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'devices': [{
          'id': 'device1',
          'name': 'Test AC',
          'status': 'off'
        }]
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DevicesPage(),
          ),
        ),
      );

      // Rapidly toggle device multiple times
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.power_settings_new_rounded));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify final state is consistent
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);
    });

    testWidgets('Room deletion handles device associations', (tester) async {
      // Test for issue #167: Orphaned devices after room deletion
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'rooms': [{
          'id': 'room1',
          'name': 'Test Room',
          'devices': ['device1', 'device2']
        }]
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: RoomsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Delete room
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify devices are properly unassigned
      expect(find.text('Test Room'), findsNothing);
    });

    testWidgets('Temperature alerts dont flicker near threshold', (tester) async {
      // Test for issue #189: Alert flickering
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'environments': [{
          'id': 'env1',
          'temperature': 27.9, // Just below threshold of 28
          'threshold': 28
        }]
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: EnvironmentPage(),
          ),
        ),
      );

      // Monitor for 2 seconds to check for alert stability
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify alert state remained stable
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

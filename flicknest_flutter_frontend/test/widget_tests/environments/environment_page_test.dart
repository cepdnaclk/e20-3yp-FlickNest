import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/environments/presentation/pages/environment.page.dart';
import '../../../test_utils.dart';

void main() {
  group('Environment Page Widget Tests', () {
    late MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
    });

    testWidgets('displays current temperature and humidity', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'environments': {
          'env1': {
            'id': 'env1',
            'name': 'Living Room',
            'temperature': 24.5,
            'humidity': 65,
            'lastUpdated': DateTime.now().toIso8601String()
          }
        }
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

      await tester.pumpAndSettle();

      expect(find.text('24.5°C'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('shows temperature history graph', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'temperature_history': [
          {'value': 24.5, 'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
          {'value': 25.0, 'timestamp': DateTime.now().toIso8601String()}
        ]
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

      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows alerts for extreme conditions', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'environments': {
          'env1': {
            'id': 'env1',
            'name': 'Living Room',
            'temperature': 30.0, // High temperature
            'humidity': 80, // High humidity
            'lastUpdated': DateTime.now().toIso8601String()
          }
        }
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

      await tester.pumpAndSettle();

      expect(find.text('High Temperature Alert'), findsOneWidget);
      expect(find.text('High Humidity Alert'), findsOneWidget);
    });

    testWidgets('can set temperature thresholds', (WidgetTester tester) async {
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

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Set new threshold
      await tester.enterText(find.byKey(const Key('maxTempField')), '28');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify threshold was updated
      expect(find.text('Max: 28°C'), findsOneWidget);
    });

    testWidgets('shows offline status when device is disconnected', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'environments': {
          'env1': {
            'id': 'env1',
            'name': 'Living Room',
            'temperature': 24.5,
            'humidity': 65,
            'lastUpdated': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'status': 'offline'
          }
        }
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

      await tester.pumpAndSettle();

      expect(find.text('Device Offline'), findsOneWidget);
    });
  });
}

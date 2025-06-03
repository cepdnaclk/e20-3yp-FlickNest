import 'package:flicknest_flutter_frontend/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/device_management.dart';
import '../../test_utils.dart' as testUtils;

void main() {
  group('Device Management Page Tests', () {
    late testUtils.MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = testUtils.MockFirebaseDatabase();
    });

    testWidgets('renders device management page UI correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Device Management'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching data', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays error message on data fetch failure', (WidgetTester tester) async {
      testUtils.TestUtils.setupMockDatabaseResponse(mockDb, null); // Simulate error

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('displays devices correctly', (WidgetTester tester) async {
      testUtils.TestUtils.setupMockDatabaseResponse(mockDb, {
        "devices": {
          "sym_001": "Device 1",
          "sym_002": "Device 2",
        },
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify devices are displayed
      expect(find.text('Device 1'), findsOneWidget);
      expect(find.text('Device 2'), findsOneWidget);
    });

    testWidgets('handles device addition', (WidgetTester tester) async {
      testUtils.TestUtils.setupMockDatabaseResponse(mockDb, {
        "availableSymbols": [
          {"id": "sym_003", "name": "Symbol 3"},
        ],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open add device dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill out form and submit
      await tester.enterText(find.byType(TextFormField), 'New Device');
      await tester.tap(find.text('Symbol 3'));
      await tester.tap(find.text('Add Device'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.textContaining('Device added successfully'), findsOneWidget);
    });

    testWidgets('handles device deletion', (WidgetTester tester) async {
      testUtils.TestUtils.setupMockDatabaseResponse(mockDb, {
        "devices": {
          "sym_001": "Device 1",
        },
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: const MaterialApp(
            home: DeviceManagementPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open delete dialog
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.textContaining('Device deleted successfully'), findsOneWidget);
    });
  });
}

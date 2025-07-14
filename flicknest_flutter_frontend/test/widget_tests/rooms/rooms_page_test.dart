import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/rooms/presentation/pages/rooms.page.dart';
import '../../../test_utils.dart';

void main() {
  group('Rooms Page Widget Tests', () {
    late MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
    });

    testWidgets('renders rooms list when data is available', (WidgetTester tester) async {
      // Setup mock data
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'rooms': [
          {
            'id': 'room1',
            'name': 'Living Room',
            'devices': ['device1', 'device2'],
            'temperature': 24.5,
            'humidity': 65
          },
          {
            'id': 'room2',
            'name': 'Bedroom',
            'devices': ['device3'],
            'temperature': 22.0,
            'humidity': 60
          }
        ]
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

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify rooms are displayed
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Bedroom'), findsOneWidget);
    });

    testWidgets('shows room details on tap', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'rooms': [
          {
            'id': 'room1',
            'name': 'Living Room',
            'devices': ['device1', 'device2'],
            'temperature': 24.5,
            'humidity': 65
          }
        ]
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
      await tester.tap(find.text('Living Room'));
      await tester.pumpAndSettle();

      // Verify room details are shown
      expect(find.text('Temperature: 24.5°C'), findsOneWidget);
      expect(find.text('Humidity: 65%'), findsOneWidget);
    });

    testWidgets('can add new room', (WidgetTester tester) async {
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

      // Tap add room button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in room details
      await tester.enterText(
        find.byType(TextField).first,
        'New Room'
      );

      // Submit form
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify room was added
      expect(find.text('New Room'), findsOneWidget);
    });

    testWidgets('can delete room', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        'rooms': [
          {
            'id': 'room1',
            'name': 'Test Room',
            'devices': [],
            'temperature': 24.0,
            'humidity': 60
          }
        ]
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

      // Open room options
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify room was removed
      expect(find.text('Test Room'), findsNothing);
    });

    testWidgets('shows empty state when no rooms exist', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {'rooms': []});

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

      expect(find.text('No rooms found'), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, null);

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

      expect(find.text('Error loading rooms'), findsOneWidget);
    });
  });
}

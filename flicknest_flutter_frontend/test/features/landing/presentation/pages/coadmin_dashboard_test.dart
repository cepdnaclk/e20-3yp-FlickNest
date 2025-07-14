import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/pages/coadmin_dashboard.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';

class TestUser extends Mock implements User {
  @override
  final String? displayName;
  @override
  final String? email;

  TestUser({this.displayName, this.email});
}

class MockDatabaseEvent extends Mock implements DatabaseEvent {
  @override
  DataSnapshot get snapshot => MockDataSnapshot();
}

class MockDataSnapshot extends Mock implements DataSnapshot {
  @override
  dynamic get value => {
        'devices': {'device1': {}, 'device2': {}},
        'rooms': {'room1': {}, 'room2': {}, 'room3': {}},
        'users': {'user1': {}, 'user2': {}, 'user3': {}, 'user4': {}},
      };
}

void main() {
  group('CoAdminDashboard Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          currentEnvironmentProvider.overrideWith((_) => EnvironmentNotifier()..setEnvironment('test-env')),
          currentAuthUserProvider.overrideWith((_) => Stream.value(
            TestUser(displayName: 'Test Admin', email: 'test@example.com'))),
          statsStreamProvider.overrideWith((_) => Stream<DatabaseEvent>.value(MockDatabaseEvent())),
        ],
      );
    });

    testWidgets('renders AppBar with correct title and username', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.text('Co-Admin Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Test Admin'), findsOneWidget);
    });

    testWidgets('displays all overview statistics correctly', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.text('2'), findsOneWidget); // Devices count
      expect(find.text('3'), findsOneWidget); // Rooms count
      expect(find.text('4'), findsOneWidget); // Users count
    });

    testWidgets('quick action buttons are rendered and clickable', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.text('Add Device'), findsOneWidget);
      expect(find.text('Add Room'), findsOneWidget);

      await tester.tap(find.text('Add Device'));
      await tester.pump();
      // Verify navigation (implement based on your navigation setup)
    });

    testWidgets('management cards are displayed correctly', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.text('Device\nManagement'), findsOneWidget);
      expect(find.text('Room\nManagement'), findsOneWidget);
      expect(find.text('System\nSettings'), findsOneWidget);
    });

    testWidgets('handles loading state correctly', (tester) async {
      final loadingContainer = ProviderContainer(
        overrides: [
          statsStreamProvider.overrideWith((_) => Stream<DatabaseEvent>.value(MockDatabaseEvent())),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles error state correctly', (tester) async {
      final errorContainer = ProviderContainer(
        overrides: [
          statsStreamProvider.overrideWith((_) => Stream<DatabaseEvent>.error('Test error', StackTrace.empty)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: errorContainer,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.text('Error: Test error'), findsOneWidget);
    });

    testWidgets('stat cards show correct icons and colors', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoAdminDashboard()),
        ),
      );

      expect(find.byIcon(Icons.devices), findsNWidgets(2));
      expect(find.byIcon(Icons.meeting_room), findsNWidgets(2));
      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });
} 
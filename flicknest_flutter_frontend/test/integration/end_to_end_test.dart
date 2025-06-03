import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flicknest_flutter_frontend/main.dart' as app;


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Flow Test', () {
    testWidgets('Complete user journey test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should start at login page
      expect(find.text('Welcome to FlickNest'), findsOneWidget);

      // Login flow with actual test user email
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('wmndilshan@gmail.com'), findsOneWidget);

      // Should be on home page after login
      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate to Rooms - verify specific rooms exist
      await tester.tap(find.byIcon(Icons.meeting_room));
      await tester.pumpAndSettle();
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Bedroom'), findsOneWidget);

      // Navigate to Devices - verify specific devices exist
      await tester.tap(find.byIcon(Icons.devices));
      await tester.pumpAndSettle();
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Living Room Light'), findsOneWidget);
      expect(find.text('Air Conditioner'), findsOneWidget);

      // Navigate to Environment
      await tester.tap(find.byIcon(Icons.thermostat));
      await tester.pumpAndSettle();
      expect(find.text('Environment'), findsOneWidget);

      // Check profile access with actual user data
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Nuwan Dilshan'), findsOneWidget);
      expect(find.text('wmndilshan@gmail.com'), findsOneWidget);

      // Logout flow
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to FlickNest'), findsOneWidget);
    });

    testWidgets('Device control flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Go to devices
      await tester.tap(find.byIcon(Icons.devices));
      await tester.pumpAndSettle();

      // Verify existing device
      expect(find.text('Living Room Light'), findsOneWidget);

      // Control existing device
      await tester.tap(find.text('Living Room Light'));
      await tester.pumpAndSettle();

      // Verify device control panel
      expect(find.text('Device Control'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('sym_001'), findsOneWidget); // Assigned symbol
    });

    testWidgets('Room management flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Go to rooms
      await tester.tap(find.byIcon(Icons.meeting_room));
      await tester.pumpAndSettle();

      // Verify existing room
      expect(find.text('Living Room'), findsOneWidget);

      // Enter room details
      await tester.tap(find.text('Living Room'));
      await tester.pumpAndSettle();

      // Verify room details page with actual devices
      expect(find.text('Room Details'), findsOneWidget);
      expect(find.text('Living Room Light'), findsOneWidget);
      expect(find.text('Living Room Fan'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
    });

    testWidgets('Environment monitoring flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login with test admin user
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Go to environment page and verify environments
      await tester.tap(find.byIcon(Icons.thermostat));
      await tester.pumpAndSettle();

      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('Smart Home'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('fourth'), findsOneWidget);
      expect(find.text('fifth'), findsOneWidget);

      // Verify environment details
      await tester.tap(find.text('Smart Home'));
      await tester.pumpAndSettle();

      // Verify users in environment
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/rooms/presentation/pages/room_details.page.dart';
import '../../../test_utils.dart';

void main() {
  group('Room Details Page Tests', () {
    late MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
    });

    testWidgets('displays room details with devices', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "env_12345": {
            "rooms": {
              "room_001": {
                "name": "Living Room",
                "devices": {
                  "dev_1001": true,
                  "dev_1002": true,
                  "dev_1003": true
                }
              }
            },
            "devices": {
              "dev_1001": {
                "name": "Living Room Light",
                "state": false
              },
              "dev_1002": {
                "name": "Living Room Fan",
                "state": true
              },
              "dev_1003": {
                "name": "TV",
                "state": true
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: MaterialApp(
            home: RoomDetailsPage(
              environmentId: "env_12345",
              roomId: "room_001"
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify room name and devices are displayed
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Living Room Light'), findsOneWidget);
      expect(find.text('Living Room Fan'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
    });

    testWidgets('can add device to room', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "env_12345": {
            "rooms": {
              "room_001": {
                "name": "Living Room",
                "devices": {}
              }
            },
            "devices": {
              "dev_1001": {
                "name": "Available Device",
                "roomId": null
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            currentUserProvider.overrideWithValue("Hv03hlt99gTXsq5zOrmqdYo5MPF2")
          ],
          child: MaterialApp(
            home: RoomDetailsPage(
              environmentId: "env_12345",
              roomId: "room_001"
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap add device button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Select device from dialog
      await tester.tap(find.text('Available Device'));
      await tester.pumpAndSettle();

      // Verify device was added
      expect(find.text('Available Device'), findsOneWidget);
    });

    testWidgets('can remove device from room', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "env_12345": {
            "rooms": {
              "room_001": {
                "name": "Living Room",
                "devices": {
                  "dev_1001": true
                }
              }
            },
            "devices": {
              "dev_1001": {
                "name": "Removable Device",
                "roomId": "room_001"
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            currentUserProvider.overrideWithValue("Hv03hlt99gTXsq5zOrmqdYo5MPF2")
          ],
          child: MaterialApp(
            home: RoomDetailsPage(
              environmentId: "env_12345",
              roomId: "room_001"
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open device menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Select remove option
      await tester.tap(find.text('Remove from Room'));
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify device was removed
      expect(find.text('Removable Device'), findsNothing);
    });

    testWidgets('displays device states correctly', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "env_12345": {
            "rooms": {
              "room_001": {
                "name": "Living Room",
                "devices": {
                  "dev_1001": true,
                  "dev_1002": true
                }
              }
            },
            "devices": {
              "dev_1001": {
                "name": "Device On",
                "state": true
              },
              "dev_1002": {
                "name": "Device Off",
                "state": false
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
          ],
          child: MaterialApp(
            home: RoomDetailsPage(
              environmentId: "env_12345",
              roomId: "room_001"
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify device states
      expect(find.byIcon(Icons.toggle_on), findsOneWidget);
      expect(find.byIcon(Icons.toggle_off), findsOneWidget);
    });
  });
}

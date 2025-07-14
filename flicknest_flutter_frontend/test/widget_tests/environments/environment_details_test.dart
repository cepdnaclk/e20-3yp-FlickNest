import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/environments/presentation/pages/environment_details.page.dart';
import '../../../test_utils.dart';

void main() {
  group('Environment Details Page Tests', () {
    late MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
    });

    testWidgets('displays environment name and user count', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "name": "fourth",
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "role": "admin",
                "name": "Nuwan Dilshan"
              },
              "zLpSk1cJt4PCxm43wjvi0SWqAx62": {
                "role": "co-admin",
                "name": "Anonymous"
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
            home: EnvironmentDetailsPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('fourth'), findsOneWidget);
      expect(find.text('Members (2)'), findsOneWidget);
    });

    testWidgets('shows correct user roles', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "name": "fourth",
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "role": "admin",
                "name": "Nuwan Dilshan"
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
            home: EnvironmentDetailsPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Nuwan Dilshan'), findsOneWidget);
    });

    testWidgets('admin can manage users', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "name": "fourth",
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "role": "admin",
                "name": "Nuwan Dilshan"
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
            home: EnvironmentDetailsPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify admin actions are available
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('non-admin cannot manage users', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "name": "fourth",
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "other_user": {
                "role": "user",
                "name": "Other User"
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            currentUserProvider.overrideWithValue("other_user")
          ],
          child: MaterialApp(
            home: EnvironmentDetailsPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify admin actions are not available
      expect(find.byIcon(Icons.person_add), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('displays room count correctly', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "name": "fourth",
            "rooms": {
              "room_001": { "name": "Living Room" },
              "room_002": { "name": "Kitchen" }
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
            home: EnvironmentDetailsPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rooms (2)'), findsOneWidget);
    });
  });
}

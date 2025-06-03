import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/features/environments/presentation/pages/user_management.page.dart';
import '../../../test_utils.dart';

void main() {
  group('User Management Tests', () {
    late MockFirebaseDatabase mockDb;

    setUp(() {
      mockDb = TestUtils.getMockDatabase();
    });

    testWidgets('displays users with correct roles', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "email": "wmndilshan@gmail.com",
                "name": "Nuwan Dilshan",
                "role": "admin"
              },
              "zLpSk1cJt4PCxm43wjvi0SWqAx62": {
                "email": "e20455@eng.pdn.ac.lk",
                "name": "Anonymous",
                "role": "co-admin"
              },
              "kZnzMGo0TbbVOdUqhvWwYlrMYH32": {
                "email": "surajwijesooriya47@gmail.com",
                "name": "Anonymous",
                "role": "user"
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
            home: UserManagementPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all users are displayed with correct roles
      expect(find.text('Nuwan Dilshan'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Co-Admin'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });

    testWidgets('admin can invite new users', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "role": "admin"
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
            home: UserManagementPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap invite button
      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      // Fill in invitation details
      await tester.enterText(
        find.byType(TextField),
        'test@example.com'
      );
      await tester.tap(find.text('User')); // Select role
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Verify invitation sent confirmation
      expect(find.text('Invitation sent'), findsOneWidget);
    });

    testWidgets('co-admin has limited management rights', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "zLpSk1cJt4PCxm43wjvi0SWqAx62": {
                "role": "co-admin"
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            currentUserProvider.overrideWithValue("zLpSk1cJt4PCxm43wjvi0SWqAx62")
          ],
          child: MaterialApp(
            home: UserManagementPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify co-admin can't access certain features
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.text('Change Admin'), findsNothing);
    });

    testWidgets('handles pending invitations', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "users": {
          "kZnzMGo0TbbVOdUqhvWwYlrMYH32": {
            "invitations": {
              "-ORZ1_4_lCb5lUDn-7fv": {
                "environmentId": "-ORZ1_4_lCb5lUDn-7fv",
                "environmentName": "fifth",
                "inviterId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
                "role": "user",
                "timestamp": 1748656345854
              }
            }
          }
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            currentUserProvider.overrideWithValue("kZnzMGo0TbbVOdUqhvWwYlrMYH32")
          ],
          child: MaterialApp(
            home: UserManagementPage(environmentId: "-ORZ1_4_lCb5lUDn-7fv"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pending invitation is shown
      expect(find.text('Pending Invitations'), findsOneWidget);
      expect(find.text('fifth'), findsOneWidget);
    });

    testWidgets('can change user roles', (WidgetTester tester) async {
      TestUtils.setupMockDatabaseResponse(mockDb, {
        "environments": {
          "-ORZ-QSZUyoPQKENzK3I": {
            "adminId": "Hv03hlt99gTXsq5zOrmqdYo5MPF2",
            "users": {
              "Hv03hlt99gTXsq5zOrmqdYo5MPF2": {
                "role": "admin"
              },
              "testUser": {
                "name": "Test User",
                "role": "user"
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
            home: UserManagementPage(environmentId: "-ORZ-QSZUyoPQKENzK3I"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open user menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Select change role option
      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();

      // Select new role
      await tester.tap(find.text('Co-Admin'));
      await tester.pumpAndSettle();

      // Verify role was updated
      expect(find.text('Co-Admin'), findsOneWidget);
    });
  });
}

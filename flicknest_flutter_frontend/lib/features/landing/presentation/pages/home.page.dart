import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_page_header.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_tile_options_panel.dart';
import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/providers/environment_provider.dart';
import 'package:flicknest_flutter_frontend/Firebase/deviceService.dart';
import 'package:flicknest_flutter_frontend/Firebase/switchModel.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/pages/coadmin_dashboard.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/pages/user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

final currentUserIdProvider = Provider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid ?? '';
});

class HomePage extends ConsumerWidget {
  static const String route = '/home';
  final DeviceService deviceService;
  final SwitchService switchService;

  const HomePage({
    Key? key,
    required this.deviceService,
    required this.switchService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environmentID = ref.watch(currentEnvironmentProvider) ?? '';
    final userID = ref.watch(currentUserIdProvider);

    // Debug: Print FirebaseAuth user info
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print('[HomePage] currentUserId (provider): $userID');
    print('[HomePage] FirebaseAuth.currentUser?.uid: ${firebaseUser?.uid}');
    print('[HomePage] FirebaseAuth.currentUser?.email: ${firebaseUser?.email}');

    // Print current user and environment info
    print('[HomePage] currentUserId: $userID');
    print('[HomePage] currentEnvironmentId: $environmentID');

    return FutureBuilder<String?>(
      future: getUserRole(environmentID, userID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print('[HomePage] Waiting for role data...');
          return const Center(child: CircularProgressIndicator());
        }
        final role = snapshot.data;
        print('snapshot.data: ${snapshot.data}');
        print('[HomePage] Role for user $userID in environment $environmentID: $role');
        if (role == null) {
          print('[HomePage] User not found in environment or no role set.');
          return const Center(
            child: Text(
              'You have no access to this environment.\nPlease contact the administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
          );
        }
        if (role == 'admin') {
          print('[HomePage] Showing AdminDashboard');
          return const AdminDashboard();
        } else if (role == 'co-admin') {
          print('[HomePage] Showing CoAdminDashboard');
          return const CoAdminDashboard();
        } else if (role == 'user') {
          print('[HomePage] Showing UserDashboard');
          return const UserDashboard();
        } else {
          print('[HomePage] Unknown role, showing no access message.');
          return const Center(
            child: Text(
              'You have no access to this environment.\nPlease contact the administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
          );
        }
      },
    );
  }
}

Future<String?> getUserRole(String environmentID, String userID) async {
  print('[getUserRole] Fetching role for user $userID in environment $environmentID');
  final ref = FirebaseDatabase.instance
      .ref('environments/$environmentID/users/$userID/role');
  final snapshot = await ref.get();
  print('[getUserRole] Firebase snapshot value: ${snapshot.value}');
  return snapshot.value as String?;
}
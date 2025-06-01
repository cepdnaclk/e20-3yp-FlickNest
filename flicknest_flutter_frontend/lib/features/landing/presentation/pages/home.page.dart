import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_page_header.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_tile_options_panel.dart';
import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/main.dart' show environmentProvider, currentUserIdProvider;
import 'package:flicknest_flutter_frontend/features/settings/presentation/pages/settings.pages.dart' show currentUserIdProvider;
import 'package:flicknest_flutter_frontend/Firebase/deviceService.dart';
import 'package:flicknest_flutter_frontend/Firebase/switchModel.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/admin_dashboard.dart';

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
    final environmentID = ref.watch(environmentProvider);
    final userID = ref.watch(currentUserIdProvider);

    return FutureBuilder<String?>(
      future: getUserRole(environmentID, userID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = snapshot.data;
        if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'co-admin') {
          return const CoAdminDashboard();
        } else {
          return const UserDashboard();
        }
      },
    );
  }
}

Future<String?> getUserRole(String environmentID, String userID) async {
  final ref = FirebaseDatabase.instance
      .ref('environments/$environmentID/users/$userID/role');
  final snapshot = await ref.get();
  return snapshot.value as String?;
}

class UserDashboard extends StatelessWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Dashboard')),
      body: const Center(child: Text('Welcome, user!')),
    );
  }
}

class CoAdminDashboard extends StatelessWidget {
  const CoAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Co-Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('View Rooms'),
              subtitle: const Text('View and monitor rooms'),
              onTap: () {
                Navigator.pushNamed(context, '/coadmin/rooms');
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('View Devices'),
              subtitle: const Text('View and control devices'),
              onTap: () {
                Navigator.pushNamed(context, '/coadmin/devices');
              },
            ),
          ),
          // Add more co-admin features as needed
        ],
      ),
    );
  }
}
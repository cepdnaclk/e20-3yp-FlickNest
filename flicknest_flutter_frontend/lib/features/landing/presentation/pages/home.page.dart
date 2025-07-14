import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart' show currentEnvironmentProvider;
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart' show currentAuthUserProvider;
import 'package:flicknest_flutter_frontend/providers/role/role_provider.dart' show currentUserRoleProvider;
import 'package:flicknest_flutter_frontend/Firebase/deviceService.dart';
import 'package:flicknest_flutter_frontend/Firebase/switchModel.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/pages/coadmin_dashboard.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/pages/user_dashboard.dart';

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
    final currentUser = ref.watch(currentAuthUserProvider).value;
    final environmentID = ref.watch(currentEnvironmentProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);

    // Debug: Print current state
    print('[HomePage] Current User: ${currentUser?.email} (${currentUser?.uid})');
    print('[HomePage] Current Environment: $environmentID');

    if (currentUser == null) {
      return const Center(child: Text('Please log in to continue'));
    }

    if (environmentID == null) {
      return const Center(
        child: Text(
          'No environment selected.\nPlease select an environment from settings.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return roleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (role) {
        if (role == null) {
          return const Center(
            child: Text(
              'You have no access to this environment.\nPlease contact the administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
          );
        }

        print('[HomePage] User Role: $role');

        switch (role) {
          case 'admin':
            return const AdminDashboard();
          case 'co-admin':
            return const CoAdminDashboard();
          case 'user':
            return const UserDashboard();
          default:
            return Center(
              child: Text(
                'Unknown role: $role\nPlease contact the administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
            );
        }
      },
    );
  }
}
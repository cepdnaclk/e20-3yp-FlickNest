import 'package:flutter/material.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import '../../../../main.dart' show themeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../../../environments/presentation/pages/create_environment.dart';
import 'settings_profile_section.dart';
import 'settings_environment_section.dart';
import 'settings_network_section.dart';
import 'settings_appearance_section.dart';
import 'settings_notifications_section.dart';
import 'settings_privacy_section.dart';
import 'settings_device_section.dart';
import 'settings_help_section.dart';
import 'settings_version_section.dart';
import '../../../../providers/network/network_mode_provider.dart';

enum NetworkMode { local, online }

class SettingsPage extends ConsumerStatefulWidget {
  static const String route = '/settings';
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool notificationsEnabled = true;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    final currentEnvId = ref.watch(currentEnvironmentProvider);
    final environmentsAsync = ref.watch(userEnvironmentsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: environmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading environments: $error'),
        ),
        data: (environments) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          children: [
            const SettingsProfileSection(),
            SettingsEnvironmentSection(
              environments: environments,
              currentEnvironmentId: currentEnvId,
              onEnvironmentSelected: (String envId) {
                ref.read(currentEnvironmentProvider.notifier).setEnvironment(envId);
              },
            ),
            const SettingsNetworkSection(),
            SettingsAppearanceSection(themeNotifier: themeNotifier),
            SettingsNotificationsSection(
              notificationsEnabled: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
            ),
            const SettingsPrivacySection(),
            const SettingsDeviceSection(),
            const SettingsHelpSection(),
            const SettingsVersionSection(),
          ],
        ),
      ),
    );
  }
}
//
class HomeAutomationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAutomationAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envId = ref.watch(currentEnvironmentProvider);
    final userId = ref.watch(currentUserIdProvider);
    final environmentsAsync = ref.watch(userEnvironmentsProvider);
    final envAsync = ref.watch(firebaseEnvProvider(envId ?? ''));

    return AppBar(
      title: environmentsAsync.when(
        loading: () => const Text('Flick Nest'),
        error: (e, _) => const Text('Flick Nest'),
        data: (environments) {
          final currentEnv = environments[envId];
          return Text(currentEnv?['name'] ?? 'Flick Nest');
        },
      ),
      actions: [
        envAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => const SizedBox(),
          data: (envData) {
            final user = envData['users'][userId];
            if (user == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: user['photoUrl'] != null
                        ? NetworkImage(user['photoUrl'])
                        : null,
                    child: user['photoUrl'] == null
                        ? Text(user['name'][0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _getRoleIcon(user['role']),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Tooltip(
          message: 'Admin',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text('Admin',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      case 'co-admin':
        return Tooltip(
          message: 'Co-Admin',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text('Co-Admin',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Tooltip(
          message: 'User',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Text('User',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

final firebaseEnvProvider = FutureProvider.family<Map, String>((ref, envId) async {
  final dbRef = FirebaseDatabase.instance.ref('environments/$envId');
  final snapshot = await dbRef.get();
  if (snapshot.exists) {
    return Map<String, dynamic>.from(snapshot.value as Map);
  } else {
    throw Exception('Environment not found');
  }
});

final currentUserIdProvider = StateProvider<String>((ref) => 'user_001');

Future<String?> getUserRole(String environmentID, String userID) async {
  final ref = FirebaseDatabase.instance
      .ref('environments/$environmentID/users/$userID/role');
  final snapshot = await ref.get();
  return snapshot.value as String?;
}

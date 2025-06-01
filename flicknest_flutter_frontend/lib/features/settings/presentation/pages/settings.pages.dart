import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../styles/styles.dart';
import '../../../profile/presentation/pages/profile.page.dart';
import 'package:go_router/go_router.dart';
import '../../../../helpers/theme_notifier.dart';
import '../../../../main.dart' show themeNotifier, environmentProvider, currentUserIdProvider, environmentsData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../environments/presentation/pages/create_environment.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitations_page.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitation_details_page.dart';
import 'settings_profile_section.dart';
import 'settings_environment_section.dart';
import 'settings_appearance_section.dart';
import 'settings_notifications_section.dart';
import 'settings_privacy_section.dart';
import 'settings_device_section.dart';
import 'settings_help_section.dart';
import 'settings_version_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  static const String route = '/settings';
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool notificationsEnabled = true;
  Map<String, dynamic> environments = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEnvironments();
  }

  Future<void> _fetchEnvironments() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          environments = {};
          isLoading = false;
        });
        return;
      }

      // First, get all environments where the user is a member
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}/environments');
      final userEnvsSnapshot = await userRef.get();
      
      if (!userEnvsSnapshot.exists) {
        setState(() {
          environments = {};
          isLoading = false;
        });
        return;
      }

      // Get the environment details for each environment ID
      final Map<String, dynamic> envs = {};
      final userEnvIds = Map<String, dynamic>.from(userEnvsSnapshot.value as Map);
      
      await Future.wait(
        userEnvIds.entries.map((entry) async {
          final envId = entry.key;
          final envRef = FirebaseDatabase.instance.ref('environments/$envId');
          final envSnapshot = await envRef.get();
          
          if (envSnapshot.exists) {
            envs[envId] = Map<String, dynamic>.from(envSnapshot.value as Map);
          }
        })
      );

      if (mounted) {
        setState(() {
          environments = envs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching environments: $e');
      if (mounted) {
        setState(() {
          environments = {};
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEnv = ref.watch(environmentProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            children: [
              const SettingsProfileSection(),
              SettingsEnvironmentSection(
                envs: environments, 
                currentEnv: currentEnv, 
                ref: ref, 
                context: context
              ),
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
    );
  }
}

class HomeAutomationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAutomationAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envId = ref.watch(environmentProvider);
    final userId = ref.watch(currentUserIdProvider);
    final envAsync = ref.watch(firebaseEnvProvider(envId));

    return envAsync.when(
      loading: () => AppBar(title: const Text('Flick Nest')),
      error: (e, _) => AppBar(title: const Text('Flick Nest')),
      data: (envData) {
        final user = envData['users'][userId];
        return AppBar(
          title: const Text('Flick Nest'),
          actions: [
            if (user != null)
              Padding(
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
                    _roleBadge(user['role']),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _roleBadge(String role) {
    switch (role) {
      case 'admin':
        return Tooltip(
          message: 'Admin',
          child: Icon(Icons.verified, color: Colors.red, size: 20),
        );
      case 'co-admin':
        return Tooltip(
          message: 'Co-Admin',
          child: Icon(Icons.verified_user, color: Colors.blue, size: 20),
        );
      default:
        return Tooltip(
          message: 'User',
          child: Icon(Icons.person, color: Colors.grey, size: 20),
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
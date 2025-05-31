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

class SettingsPage extends ConsumerWidget {
  static const String route = '/settings';
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEnv = ref.watch(environmentProvider);

    // Fetch all environments (you may want to cache or paginate in production)
    final dbRef = FirebaseDatabase.instance.ref('environments');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder(
        future: dbRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final envs = (snapshot.data!.value as Map).cast<String, dynamic>();
          return ListView(
            children: [
              // Profile Section
              Padding(
                padding: HomeAutomationStyles.mediumPadding,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                          ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                          : null,
                      child: FirebaseAuth.instance.currentUser?.photoURL == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous User',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? 'No email',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.go(ProfilePage.route);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Invitations and Environment Section
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Invitations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.go(InvitationsPage.route);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Environment'),
                subtitle: Text(envs[currentEnv]?['name'] ?? currentEnv),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Environment'),
                      children: [
                        // Create Environment Option
                        SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(context); // Close the dialog
                            final newEnvId = await context.push<String>(CreateEnvironmentPage.route);
                            if (newEnvId != null) {
                              ref.read(environmentProvider.notifier).state = newEnvId;
                            }
                          },
                          child: const ListTile(
                            leading: Icon(Icons.add_circle_outline),
                            title: Text('Create New Environment'),
                            subtitle: Text('Set up a new environment'),
                          ),
                        ),
                        const Divider(),
                        // Existing Environments
                        ...envs.entries.map((entry) {
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, entry.key),
                            child: ListTile(
                              title: Text(entry.value['name']),
                              subtitle: Text(entry.value['adminId'] == FirebaseAuth.instance.currentUser?.uid
                                  ? 'Admin'
                                  : entry.value['users']?[FirebaseAuth.instance.currentUser?.uid]?['role'] ?? 'User'),
                              selected: entry.key == currentEnv,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                  if (selected != null && selected != currentEnv) {
                    ref.read(environmentProvider.notifier).state = selected;
                  }
                },
              ),
              const Divider(),

              // Appearance Section
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance'),
                subtitle: Text(
                  themeNotifier.value == ThemeMode.light
                      ? 'Light'
                      : themeNotifier.value == ThemeMode.dark
                          ? 'Dark'
                          : 'System',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showDialog<ThemeMode>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Choose Theme'),
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          groupValue: themeNotifier.value,
                          title: const Text('System Default'),
                          onChanged: (mode) => Navigator.pop(context, mode),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: themeNotifier.value,
                          title: const Text('Light'),
                          onChanged: (mode) => Navigator.pop(context, mode),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: themeNotifier.value,
                          title: const Text('Dark'),
                          onChanged: (mode) => Navigator.pop(context, mode),
                        ),
                      ],
                    ),
                  );
                  if (selected != null) {
                    themeNotifier.setTheme(selected);
                  }
                },
              ),

              // Notifications Section
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push Notifications'),
                subtitle: const Text('Enable or disable notifications'),
                value: true, // TODO: Get actual value from settings
                onChanged: (bool value) {
                  // TODO: Update notification settings
                },
              ),

              // Privacy & Security Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to privacy settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to security settings
                },
              ),

              // Device Settings Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Device Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.devices_other),
                title: const Text('Connected Devices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to device settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('Network Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to network settings
                },
              ),

              // Help & Support Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help Center'),
                onTap: () {
                  // TODO: Navigate to help center
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to about page
                },
              ),

              // App Version
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          );
        },
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
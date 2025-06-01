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
    final userID = ref.watch(currentUserIdProvider);

    // Fetch all environments
    final dbRef = FirebaseDatabase.instance.ref('environments');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder(
        future: dbRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final envs = (snapshot.data!.value as Map).cast<String, dynamic>();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            children: [
              // Profile Section
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                            : null,
                        child: FirebaseAuth.instance.currentUser?.photoURL == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous User',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? 'No email',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          context.go(ProfilePage.route);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Invitations and Environment Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.mail_outline, color: Colors.deepPurple),
                      title: const Text('Invitations'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.go(InvitationsPage.route);
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(
                        envs[currentEnv]?['name'] ?? currentEnv,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        'Tap to switch environment',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down, size: 28),
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Select Environment'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            children: [
                              // Create Environment Option
                              SimpleDialogOption(
                                onPressed: () async {
                                  Navigator.pop(context); // Close the dialog
                                  final newEnvId = await context.push<String>(CreateEnvironmentPage.route);
                                  if (newEnvId != null) {
                                    ref.read(environmentProvider.notifier).state = newEnvId;
                                    context.go('/home');
                                  }
                                },
                                child: const ListTile(
                                  leading: Icon(Icons.add_circle_outline, color: Colors.green),
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
                                    leading: Icon(
                                      entry.key == currentEnv
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: entry.key == currentEnv
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                    ),
                                    title: Text(entry.value['name']),
                                    subtitle: Text(
                                      entry.value['adminId'] == FirebaseAuth.instance.currentUser?.uid
                                          ? 'Admin'
                                          : entry.value['users']?[FirebaseAuth.instance.currentUser?.uid]?['role'] ?? 'User'
                                    ),
                                    selected: entry.key == currentEnv,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                        if (selected != null && selected != currentEnv) {
                          ref.read(environmentProvider.notifier).state = selected;
                          context.go('/home');
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Appearance Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Colors.orange),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ),

              // Notifications Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text('Notifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined, color: Colors.teal),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Enable or disable notifications'),
                  value: true, // TODO: Get actual value from settings
                  onChanged: (bool value) {
                    // TODO: Update notification settings
                  },
                ),
              ),

              // Privacy & Security Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text('Privacy & Security', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Colors.redAccent),
                      title: const Text('Privacy Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to privacy settings
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.security, color: Colors.indigo),
                      title: const Text('Security'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to security settings
                      },
                    ),
                  ],
                ),
              ),

              // Device Settings Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text('Device Settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.devices_other, color: Colors.brown),
                      title: const Text('Connected Devices'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to device settings
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.wifi, color: Colors.blueGrey),
                      title: const Text('Network Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to network settings
                      },
                    ),
                  ],
                ),
              ),

              // Help & Support Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text('Help & Support', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Colors.green),
                      title: const Text('Help Center'),
                      onTap: () {
                        // TODO: Navigate to help center
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.blue),
                      title: const Text('About'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to about page
                      },
                    ),
                  ],
                ),
              ),

              // App Version
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

Future<String?> getUserRole(String environmentID, String userID) async {
  final ref = FirebaseDatabase.instance
      .ref('environments/$environmentID/users/$userID/role');
  final snapshot = await ref.get();
  return snapshot.value as String?;
}
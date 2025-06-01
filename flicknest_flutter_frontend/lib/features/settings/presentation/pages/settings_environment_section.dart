import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart' show environmentProvider;
import '../../../environments/presentation/pages/create_environment.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitations_page.dart';

class SettingsEnvironmentSection extends StatelessWidget {
  final Map envs;
  final String currentEnv;
  final WidgetRef ref;
  final BuildContext context;
  const SettingsEnvironmentSection({super.key, required this.envs, required this.currentEnv, required this.ref, required this.context});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.home, color: theme.colorScheme.primary),
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
                    ...envs.entries.map((entry) {
                      return SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, entry.key),
                        child: ListTile(
                          leading: Icon(
                            entry.key == currentEnv
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: entry.key == currentEnv
                                ? theme.colorScheme.primary
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
    );
  }
} 
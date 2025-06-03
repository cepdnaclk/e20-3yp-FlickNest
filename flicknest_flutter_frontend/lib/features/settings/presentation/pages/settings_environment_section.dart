import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart' show environmentProvider;
import '../../../environments/presentation/pages/create_environment.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitations_page.dart';

class SettingsEnvironmentSection extends StatelessWidget {
  final Map<String, dynamic> environments;
  final String? currentEnvironmentId;
  final Function(String) onEnvironmentSelected;

  const SettingsEnvironmentSection({
    Key? key,
    required this.environments,
    required this.currentEnvironmentId,
    required this.onEnvironmentSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentEnv = currentEnvironmentId != null ? environments[currentEnvironmentId] : null;
    final currentUser = FirebaseAuth.instance.currentUser;
    final userRole = currentEnv?['users']?[currentUser?.uid]?['role'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Environment',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.home_work),
                title: Text(
                  currentEnv?['name'] ?? 'Select Environment',
                  style: theme.textTheme.titleMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getRoleIcon(userRole),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      titlePadding: EdgeInsets.zero,
                      title: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              child: Row(
                                children: [
                                  const Text('Environments'),
                                  const Spacer(),
                                  IconButton.filled(
                                    icon: const Icon(Icons.add_home_work),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.green.withOpacity(0.1),
                                      foregroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push(CreateEnvironmentPage.route);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...environments.entries.map((entry) {
                              final envId = entry.key;
                              final env = entry.value;
                              final envUserRole = env['users'][currentUser?.uid]?['role'] ?? '';
                              return ListTile(
                                leading: Icon(
                                  Icons.home_work,
                                  color: envId == currentEnvironmentId ? theme.colorScheme.primary : null,
                                ),
                                title: Text(env['name'] ?? 'Unnamed Environment'),
                                trailing: _getRoleIcon(envUserRole),
                                selected: envId == currentEnvironmentId,
                                onTap: () {
                                  onEnvironmentSelected(envId);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.mail_outline, color: Colors.blue),
                title: const Text('Invitations'),
                onTap: () => context.push(InvitationsPage.route),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getRoleIcon(String role) {
    IconData icon;
    Color color;
    String tooltip;

    switch (role) {
      case 'admin':
        icon = Icons.admin_panel_settings;
        color = Colors.blue;
        tooltip = 'Admin';
        break;
      case 'co-admin':
        icon = Icons.security;
        color = Colors.teal;
        tooltip = 'Co-Admin';
        break;
      default:
        icon = Icons.person_outline;
        color = Colors.grey;
        tooltip = 'User';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

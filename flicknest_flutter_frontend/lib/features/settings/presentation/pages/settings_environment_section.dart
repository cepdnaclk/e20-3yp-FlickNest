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
              ...environments.entries.map((entry) {
                final envId = entry.key;
                final env = entry.value;
                final isSelected = envId == currentEnvironmentId;

                return ListTile(
                  leading: Icon(
                    Icons.home_work,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    env['name'] ?? 'Unnamed Environment',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text('ID: $envId'),
                  selected: isSelected,
                  onTap: () => onEnvironmentSelected(envId),
                );
              }).toList(),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.add_home_work, color: Colors.green),
                title: const Text('Create Environment'),
                onTap: () => context.push(CreateEnvironmentPage.route),
              ),
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
} 
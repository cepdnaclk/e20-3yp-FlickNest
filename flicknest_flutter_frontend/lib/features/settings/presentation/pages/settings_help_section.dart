import 'package:flutter/material.dart';

class SettingsHelpSection extends StatelessWidget {
  const SettingsHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
          child: Text('Help & Support', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
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
      ],
    );
  }
} 
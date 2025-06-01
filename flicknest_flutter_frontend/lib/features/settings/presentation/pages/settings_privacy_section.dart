import 'package:flutter/material.dart';

class SettingsPrivacySection extends StatelessWidget {
  const SettingsPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
          child: Text('Privacy & Security', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
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
      ],
    );
  }
} 
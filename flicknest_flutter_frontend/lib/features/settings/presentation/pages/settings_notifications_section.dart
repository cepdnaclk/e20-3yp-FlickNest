import 'package:flutter/material.dart';

class SettingsNotificationsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onChanged;
  const SettingsNotificationsSection({super.key, required this.notificationsEnabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
          child: Text('Notifications', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: Colors.teal),
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable or disable notifications'),
            value: notificationsEnabled,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
} 
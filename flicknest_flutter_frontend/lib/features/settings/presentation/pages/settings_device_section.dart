import 'package:flutter/material.dart';

class SettingsDeviceSection extends StatelessWidget {
  const SettingsDeviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
          child: Text('Device Settings', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
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
      ],
    );
  }
} 
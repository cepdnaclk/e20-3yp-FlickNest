import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/network/network_mode_provider.dart';

class SettingsNetworkSection extends ConsumerWidget {
  const SettingsNetworkSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final networkMode = ref.watch(networkModeProvider);
    final isLocal = networkMode == NetworkMode.local;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Network',
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
              SwitchListTile(
                title: const Text('Network Mode'),
                subtitle: Text(
                  isLocal ? 'Local Mode (Offline)' : 'Online Mode (Cloud)',
                  style: TextStyle(
                    color: isLocal ? Colors.green : Colors.blue,
                  ),
                ),
                secondary: Icon(
                  isLocal ? Icons.lan : Icons.cloud,
                  color: isLocal ? Colors.green : Colors.blue,
                ),
                value: isLocal,
                onChanged: (bool value) {
                  ref.read(networkModeProvider.notifier).state =
                    value ? NetworkMode.local : NetworkMode.online;
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(
                  Icons.router,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Local Broker Settings'),
                subtitle: const Text('Configure local broker connection'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  // Navigate to local broker settings
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

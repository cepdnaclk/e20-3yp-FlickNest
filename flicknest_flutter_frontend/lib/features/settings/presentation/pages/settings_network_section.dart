import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/broker_settings_provider.dart';

class SettingsNetworkSection extends ConsumerWidget {
  const SettingsNetworkSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final useLocalBroker = ref.watch(brokerSettingsProvider);

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
                title: const Text('Broker Mode'),
                subtitle: Text(
                  useLocalBroker ? 'Using Local Broker' : 'Using Online Broker',
                  style: TextStyle(
                    color: useLocalBroker ? Colors.green : Colors.blue,
                  ),
                ),
                secondary: Icon(
                  useLocalBroker ? Icons.lan : Icons.cloud,
                  color: useLocalBroker ? Colors.green : Colors.blue,
                ),
                value: useLocalBroker,
                onChanged: (bool value) {
                  ref.read(brokerSettingsProvider.notifier).toggleBrokerMode();
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(
                  useLocalBroker ? Icons.settings_ethernet : Icons.cloud_sync,
                  color: useLocalBroker ? Colors.green : Colors.blue,
                ),
                title: Text(useLocalBroker ? 'Local Broker Status' : 'Cloud Sync Status'),
                subtitle: Text(
                  useLocalBroker ? 'Connected to local network' : 'Synced with Firebase',
                  style: TextStyle(
                    color: useLocalBroker ? Colors.green : Colors.blue,
                  ),
                ),
                trailing: Icon(
                  Icons.circle,
                  size: 12,
                  color: useLocalBroker ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

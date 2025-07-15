import 'package:flicknest_flutter_frontend/features/settings/presentation/pages/settings_local_broker_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/environment/environment_provider.dart';
import '../../../../providers/network/network_mode_provider.dart';
import '../../../devices/services/device_operations_service.dart';

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
                onChanged: (bool value) async {
                  if (!value && isLocal) {  // Switching from local to online
                    try {
                      final envId = ref.read(currentEnvironmentProvider);
                      if (envId != null) {
                        final deviceOpsService = DeviceOperationsService(envId);
                        await deviceOpsService.syncLocalChangesToFirebase();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Failed to sync local changes. Some device states may be out of sync.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                  ref.read(networkModeProvider.notifier).state =
                    value ? NetworkMode.local : NetworkMode.online;
                },
              ),
              if (isLocal)
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
                enabled: isLocal,
                onTap: isLocal
                    ? () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black45,
                          builder: (context) => Dialog(
                            backgroundColor: Theme.of(context).cardColor,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Container(
                              width: 400,
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.router_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Local Broker Settings',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Configure your local broker connection',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: SettingsLocalBrokerSection(
                                          onSave: () => Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

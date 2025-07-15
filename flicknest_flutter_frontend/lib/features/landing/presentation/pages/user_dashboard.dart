import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';

// Provider for stats stream
final statsStreamProvider = StreamProvider<DatabaseEvent>((ref) {
  final envId = ref.watch(currentEnvironmentProvider);
  final user = ref.watch(currentAuthUserProvider).value;
  
  if (user == null || envId == null) {
    throw Exception('No user logged in or no environment selected');
  }
  
  return FirebaseDatabase.instance.ref('environments/$envId').onValue;
});

class UserDashboard extends ConsumerWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsStream = ref.watch(statsStreamProvider);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(theme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(theme, statsStream),
                    const SizedBox(height: 20),
                    _buildSystemSettings(theme, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentAuthUserProvider).value;
              return Text(
                'Welcome, ${user?.displayName ?? 'User'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, AsyncValue<DatabaseEvent> statsStream) {
    return statsStream.when(
      data: (snapshot) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return const SizedBox();

        int totalDevices = 0;
        int totalRooms = 0;

        // Count devices and rooms
        if (data['devices'] is Map) totalDevices = (data['devices'] as Map).length;
        if (data['rooms'] is Map) totalRooms = (data['rooms'] as Map).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Active Devices',
                    totalDevices.toString(),
                    Icons.devices,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Available Rooms',
                    totalRooms.toString(),
                    Icons.meeting_room,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettings(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            title: const Text('System Settings'),
            subtitle: const Text('Configure app preferences and notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

class CoAdminDashboard extends StatelessWidget {
  const CoAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-Admin Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.meeting_room, color: theme.colorScheme.primary),
              title: const Text('View Rooms'),
              subtitle: const Text('View and monitor rooms'),
              onTap: () {
                Navigator.pushNamed(context, '/coadmin/rooms');
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.devices, color: theme.colorScheme.primary),
              title: const Text('View Devices'),
              subtitle: const Text('View and control devices'),
              onTap: () {
                Navigator.pushNamed(context, '/coadmin/devices');
              },
            ),
          ),
          // Add more co-admin features as needed
        ],
      ),
    );
  }
} 
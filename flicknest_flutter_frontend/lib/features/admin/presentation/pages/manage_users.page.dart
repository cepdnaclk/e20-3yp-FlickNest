import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';
import 'user_device_access.page.dart';

// Provider for environment users stream
final environmentUsersStreamProvider = StreamProvider.autoDispose<DatabaseEvent>((ref) {
  final envId = ref.watch(currentEnvironmentProvider);
  final user = ref.watch(currentAuthUserProvider).value;

  // Handle no user logged in
  if (user == null) {
    throw Exception('Please log in to view users');
  }

  // Handle no environment selected
  if (envId == null) {
    throw Exception('Please select an environment first');
  }

  // Check if user has access to this environment
  return FirebaseDatabase.instance
      .ref('environments/$envId/users')
      .onValue;
});

class ManageUsersPage extends ConsumerStatefulWidget {
  static const String route = '/admin/users';
  
  const ManageUsersPage({super.key});

  @override
  ConsumerState<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends ConsumerState<ManageUsersPage> {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersStream = ref.watch(environmentUsersStreamProvider);
    final currentEnv = ref.watch(currentEnvironmentProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showSearchBar
              ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.5)),
                  ),
                  style: TextStyle(color: theme.colorScheme.onBackground),
                  autofocus: true,
                  onChanged: (value) => setState(() {}),
                )
              : Text('Manage Users${currentEnv != null ? ' - ${currentEnv.substring(0, 8)}...' : ''}'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onBackground,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            tooltip: _showSearchBar ? 'Close search' : 'Search users',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteUserDialog,
            tooltip: 'Invite user',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteUserDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Invite User', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: usersStream.when(
        data: (snapshot) {
          if (!snapshot.snapshot.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users found in this environment',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showInviteUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Users'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map<dynamic, dynamic>);
          final filteredUsers = _showSearchBar && _searchController.text.isNotEmpty
              ? users.entries.where((entry) {
                  final userData = entry.value as Map<dynamic, dynamic>;
                  final userName = (userData['name'] as String?) ?? '';
                  final userEmail = (userData['email'] as String?) ?? '';
                  final searchTerm = _searchController.text.toLowerCase();
                  return userName.toLowerCase().contains(searchTerm) ||
                         userEmail.toLowerCase().contains(searchTerm);
                }).toList()
              : users.entries.toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView.builder(
              key: ValueKey<int>(filteredUsers.length),
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final entry = filteredUsers[index];
                final userId = entry.key;
                final userData = entry.value as Map<dynamic, dynamic>;
                final userRole = (userData['role'] as String?) ?? 'user';
                final userName = (userData['name'] as String?) ?? 'Unknown User';
                final userEmail = (userData['email'] as String?) ?? 'No email';

                return _buildUserCard(
                  userId: userId,
                  userName: userName,
                  userEmail: userEmail,
                  userRole: userRole,
                  theme: theme,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading users...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (error.toString().contains('select an environment'))
                ElevatedButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Go to Settings'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToUserAccessPage(userId, userName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_$userId',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole[0].toUpperCase() + userRole.substring(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                onSelected: (value) => _handleUserAction(value, userId, userRole),
                itemBuilder: (context) => [
                  if (userRole != 'admin')
                    PopupMenuItem<String>(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Promote to Co-Admin'),
                        ],
                      ),
                    ),
                  if (userRole == 'co-admin')
                    PopupMenuItem<String>(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          const Text('Demote to User'),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        const Text('Remove User'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUserAction(String action, String userId, String currentRole) async {
    final envId = ref.read(currentEnvironmentProvider);
    if (envId == null) return;

    final userRef = FirebaseDatabase.instance
        .ref('environments/$envId/users/$userId');

    try {
      switch (action) {
        case 'promote':
          await userRef.update({'role': 'co-admin'});
          _showSnackBar('User promoted to Co-Admin');
          break;
        case 'demote':
          await userRef.update({'role': 'user'});
          _showSnackBar('User demoted to User');
          break;
        case 'remove':
          // Show confirmation dialog
          if (!mounted) return;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove User'),
              content: const Text('Are you sure you want to remove this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await userRef.remove();
            // Also remove from user's environments
            await FirebaseDatabase.instance
                .ref('users/$userId/environments/$envId')
                .remove();
            _showSnackBar('User removed');
          }
          break;
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showInviteUserDialog() {
    final emailController = TextEditingController();
    final roleController = TextEditingController(text: 'user');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Invite User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter user email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: roleController.text,
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(Icons.admin_panel_settings),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'co-admin', child: Text('Co-Admin')),
              ],
              onChanged: (value) => roleController.text = value ?? 'user',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final email = emailController.text.trim();
              final role = roleController.text;
              
              if (email.isEmpty) {
                _showSnackBar('Please enter an email', isError: true);
                return;
              }

              try {
                final envId = ref.read(currentEnvironmentProvider);
                if (envId == null) throw Exception('No environment selected');

                final invitationRef = FirebaseDatabase.instance.ref('invitations').push();
                await invitationRef.set({
                  'environmentId': envId,
                  'email': email,
                  'role': role,
                  'status': 'pending',
                  'createdAt': ServerValue.timestamp,
                });

                if (!mounted) return;
                Navigator.pop(context);
                _showSnackBar('Invitation sent to $email');
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _navigateToUserAccessPage(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDeviceAccessPage(userId: userId, userName: userName),
      ),
    );
  }

  void _showUserDevicesDialog(String userId, String userName) async {
    final envId = ref.read(currentEnvironmentProvider);
    if (envId == null) return;
    final devicesRef = FirebaseDatabase.instance.ref('environments/$envId/devices');
    final roomsRef = FirebaseDatabase.instance.ref('environments/$envId/rooms');
    final devicesSnapshot = await devicesRef.get();
    final roomsSnapshot = await roomsRef.get();
    if (!devicesSnapshot.exists) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Devices for $userName'),
          content: const Text('No devices found.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    final devicesData = Map<String, dynamic>.from(devicesSnapshot.value as Map);
    final roomsData = roomsSnapshot.exists
      ? Map<String, dynamic>.from(roomsSnapshot.value as Map)
      : <String, dynamic>{};
    // Group devices by room
    Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
    devicesData.forEach((deviceId, deviceInfo) {
      final device = Map<String, dynamic>.from(deviceInfo as Map);
      final allowedUsers = device['allowedUsers'] != null
        ? Map<String, dynamic>.from(device['allowedUsers'] as Map)
        : <String, dynamic>{};
      if (allowedUsers.containsKey(userId)) {
        final roomId = device['roomId'] as String? ?? '';
        devicesByRoom.putIfAbsent(roomId, () => []);
        devicesByRoom[roomId]!.add({
          'id': deviceId,
          'name': device['name'] ?? 'Unknown Device',
        });
      }
    });
    // Build dialog content
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Devices for $userName'),
          content: devicesByRoom.isEmpty
              ? const Text('No devices assigned to this user.')
              : SizedBox(
                  width: 350,
                  child: ListView(
                    shrinkWrap: true,
                    children: devicesByRoom.entries.map((entry) {
                      final roomId = entry.key;
                      final roomName = roomsData[roomId] != null
                        ? (roomsData[roomId]['name'] ?? 'Unknown Room')
                        : (roomId.isEmpty ? 'Unassigned' : 'Unknown Room');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ...entry.value.map((device) => ListTile(
                                title: Text(device['name']),
                                subtitle: Text('ID: ${device['id']}'),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        );
      },
    );
  }
}


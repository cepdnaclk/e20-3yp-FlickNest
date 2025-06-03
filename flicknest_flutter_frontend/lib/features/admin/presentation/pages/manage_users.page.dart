import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';
import 'package:flicknest_flutter_frontend/providers/auth/auth_provider.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersStream = ref.watch(environmentUsersStreamProvider);
    final currentEnv = ref.watch(currentEnvironmentProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users${currentEnv != null ? ' - ${currentEnv.substring(0, 8)}...' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteUserDialog,
          ),
        ],
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
                  const Text(
                    'No users found in this environment',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showInviteUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Users'),
                  ),
                ],
              ),
            );
          }

          final users = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map<dynamic, dynamic>
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userId = users.keys.elementAt(index);
              final userData = users[userId] as Map<dynamic, dynamic>;
              final userRole = (userData['role'] as String?) ?? 'user';
              final userName = (userData['name'] as String?) ?? 'Unknown User';
              final userEmail = (userData['email'] as String?) ?? 'No email';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userEmail),
                      Text(
                        'Role: ${userRole[0].toUpperCase() + userRole.substring(1)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, userId, userRole),
                    itemBuilder: (context) => [
                      if (userRole != 'admin') ...[
                        const PopupMenuItem(
                          value: 'promote',
                          child: Text('Promote to Co-Admin'),
                        ),
                      ],
                      if (userRole == 'co-admin') ...[
                        const PopupMenuItem(
                          value: 'demote',
                          child: Text('Demote to User'),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove User'),
                      ),
                    ],
                  ),
                ),
              );
            },
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
        title: const Text('Invite User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter user email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: roleController.text,
              decoration: const InputDecoration(
                labelText: 'Role',
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
          TextButton(
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

                // Create invitation
                final invitationRef = FirebaseDatabase.instance
                    .ref('invitations')
                    .push();

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
            child: const Text('Send Invitation'),
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
} 
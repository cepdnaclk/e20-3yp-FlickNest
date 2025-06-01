import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  static const String route = '/admin/users';
  
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('environments/env_12345/users');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _usersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No users found.'),
            );
          }

          final usersData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserStats(usersData),
                const SizedBox(height: 24),
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildUserList(usersData),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserStats(Map<String, dynamic> usersData) {
    int totalUsers = usersData.length;
    int adminCount = 0;
    int regularCount = 0;

    usersData.forEach((_, user) {
      if (user is Map && user.containsKey('role')) {
        if (user['role'] == 'admin') {
          adminCount++;
        } else {
          regularCount++;
        }
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Users', totalUsers.toString()),
            _buildStatItem('Admins', adminCount.toString()),
            _buildStatItem('Regular Users', regularCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(Map<String, dynamic> usersData) {
    return ListView.builder(
      itemCount: usersData.length,
      itemBuilder: (context, index) {
        final userId = usersData.keys.elementAt(index);
        final user = usersData[userId] as Map<dynamic, dynamic>;
        final isAdmin = user['role'] == 'admin';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? Colors.orange : null,
            ),
            title: Text(user['name'] ?? 'Unnamed User'),
            subtitle: Text(user['email'] ?? 'No email'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isAdmin,
                  onChanged: (value) => _updateUserRole(userId, value),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteUserDialog(context, userId),
                ),
              ],
            ),
            onTap: () => _showUserDetailsDialog(context, userId, user),
          ),
        );
      },
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Admin User'),
                    Switch(
                      value: isAdmin,
                      onChanged: (value) => setState(() => isAdmin = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newUserRef = _usersRef.push();
                  await newUserRef.set({
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': isAdmin ? 'admin' : 'user',
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, bool isAdmin) async {
    await _usersRef.child(userId).update({
      'role': isAdmin ? 'admin' : 'user',
    });
  }

  Future<void> _showDeleteUserDialog(BuildContext context, String userId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _usersRef.child(userId).remove();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserDetailsDialog(
    BuildContext context,
    String userId,
    Map<dynamic, dynamic> user,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name'] as String? ?? 'User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $userId'),
            const SizedBox(height: 8),
            Text('Email: ${user['email'] ?? 'No email'}'),
            const SizedBox(height: 8),
            Text('Role: ${user['role'] ?? 'No role'}'),
            if (user['devices'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Assigned Devices:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...((user['devices'] as Map).keys).map(
                (deviceId) => ListTile(
                  leading: const Icon(Icons.device_hub),
                  title: Text(deviceId as String),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 
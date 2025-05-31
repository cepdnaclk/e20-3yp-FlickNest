import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEnvironmentPage extends ConsumerStatefulWidget {
  static const String route = '/create-environment';
  const CreateEnvironmentPage({super.key});

  @override
  ConsumerState<CreateEnvironmentPage> createState() => _CreateEnvironmentPageState();
}

class _CreateEnvironmentPageState extends ConsumerState<CreateEnvironmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _coAdminController = TextEditingController();
  final _userController = TextEditingController();
  bool _isLoading = false;
  String? _coAdminId;
  Map<String, dynamic>? _coAdminUser;
  final Set<String> _selectedUserIds = {};
  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  List<Map<String, dynamic>> _coAdminSuggestions = [];
  List<Map<String, dynamic>> _userSuggestions = [];
  String? _currentUserEmail;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserEmail = currentUser.email;
        _currentUserName = currentUser.displayName ?? 'Anonymous';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coAdminController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _searchUsersByEmail(String query) async {
    debugPrint('[SEARCH] Start search by email: "$query"');
    if (query.length < 3) {
      debugPrint('[SEARCH] Query too short: "$query"');
      return [];
    }
    final usersRef = FirebaseDatabase.instance.ref('users');
    final snapshot = await usersRef
        .orderByChild('email')
        .startAt(query.toLowerCase())
        .endAt('${query.toLowerCase()}\uf8ff')
        .get();
    if (!snapshot.exists || snapshot.value is! Map) {
      debugPrint('[SEARCH] No users found for "$query"');
      return [];
    }
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final users = (snapshot.value as Map).entries
        .where((e) => e.key != currentUserId)
        .map((e) => {
              'id': e.key,
              ...Map<String, dynamic>.from(e.value as Map),
            })
        .toList();
    debugPrint('[SEARCH] Found users for "$query": ${users.map((u) => u['email']).toList()}');
    return users;
  }

  Future<void> _onCoAdminChanged(String query) async {
    debugPrint('[CO-ADMIN] onChanged: "$query"');
    if (query.length < 3) {
      setState(() => _coAdminSuggestions = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await _searchUsersByEmail(query);
    setState(() {
      _coAdminSuggestions = results;
      _isLoading = false;
    });
    debugPrint('[CO-ADMIN] Suggestions updated: ${results.map((u) => u['email']).toList()}');
  }

  Future<void> _onUserChanged(String query) async {
    debugPrint('[USER] onChanged: "$query"');
    if (query.length < 3) {
      setState(() => _userSuggestions = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await _searchUsersByEmail(query);
    setState(() {
      _userSuggestions = results;
      _isLoading = false;
    });
    debugPrint('[USER] Suggestions updated: ${results.map((u) => u['email']).toList()}');
  }

  Future<void> _onCoAdminSearchButton() async {
    final query = _coAdminController.text.trim();
    debugPrint('[CO-ADMIN] Search button pressed with query: "$query"');
    setState(() => _isLoading = true);
    final results = await _searchUsersByEmail(query);
    setState(() {
      _coAdminSuggestions = results;
      _isLoading = false;
    });
    debugPrint('[CO-ADMIN] Search button results: ${results.map((u) => u['email']).toList()}');
  }

  Future<void> _onUserSearchButton() async {
    final query = _userController.text.trim();
    debugPrint('[USER] Search button pressed with query: "$query"');
    setState(() => _isLoading = true);
    final results = await _searchUsersByEmail(query);
    setState(() {
      _userSuggestions = results;
      _isLoading = false;
    });
    debugPrint('[USER] Search button results: ${results.map((u) => u['email']).toList()}');
  }

  void _selectCoAdmin(Map<String, dynamic> user) {
    debugPrint('[CO-ADMIN] Selected: ${user['email']} (id: ${user['id']})');
    setState(() {
      _coAdminId = user['id'] as String;
      _coAdminUser = user;
      _coAdminController.text = user['email'] as String;
      _coAdminSuggestions = [];
    });
  }

  void _removeCoAdmin() {
    debugPrint('[CO-ADMIN] Removed co-admin');
    setState(() {
      _coAdminId = null;
      _coAdminUser = null;
      _coAdminController.clear();
    });
  }

  void _addUser(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    if (_selectedUserIds.contains(userId) || userId == _coAdminId) return;
    debugPrint('[USER] Added: ${user['email']} (id: $userId)');
    setState(() {
      _selectedUserIds.add(userId);
      _selectedUsers[userId] = user;
      _userController.clear();
      _userSuggestions = [];
    });
  }

  void _removeUser(String userId) {
    debugPrint('[USER] Removed: $userId');
    setState(() {
      _selectedUserIds.remove(userId);
      _selectedUsers.remove(userId);
    });
  }

  Future<void> _createEnvironment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');
      final newEnvRef = FirebaseDatabase.instance.ref('environments').push();
      final envId = newEnvRef.key!;
      final Map<String, dynamic> envData = {
        'adminId': currentUser.uid,
        'name': _nameController.text.trim(),
        'createdAt': ServerValue.timestamp,
        'users': {
          currentUser.uid: {
            'email': currentUser.email,
            'name': currentUser.displayName ?? 'Anonymous',
            'role': 'admin',
            'addedAt': ServerValue.timestamp,
          }
        }
      };
      if (_coAdminId != null && _coAdminUser != null) {
        envData['users'][_coAdminId!] = {
          'email': _coAdminUser!['email'],
          'name': _coAdminUser!['name'] ?? 'Anonymous',
          'role': 'co-admin',
          'addedAt': ServerValue.timestamp,
        };
      }
      for (final userId in _selectedUserIds) {
        final user = _selectedUsers[userId]!;
        envData['users'][userId] = {
          'email': user['email'],
          'name': user['name'] ?? 'Anonymous',
          'role': 'user',
          'addedAt': ServerValue.timestamp,
        };
      }
      await newEnvRef.set(envData);

      // Add invitations for co-admin and users
      final inviterId = currentUser.uid;
      final envName = _nameController.text.trim();
      final List<Future> invitationFutures = [];
      // Co-admin invitation
      if (_coAdminId != null && _coAdminUser != null) {
        final coAdminInvitationRef = FirebaseDatabase.instance.ref('users/${_coAdminId!}/invitations/$envId');
        invitationFutures.add(coAdminInvitationRef.set({
          'environmentId': envId,
          'environmentName': envName,
          'inviterId': inviterId,
          'role': 'co-admin',
          'timestamp': ServerValue.timestamp,
        }));
      }
      // User invitations
      for (final userId in _selectedUserIds) {
        final userInvitationRef = FirebaseDatabase.instance.ref('users/$userId/invitations/$envId');
        invitationFutures.add(userInvitationRef.set({
          'environmentId': envId,
          'environmentName': envName,
          'inviterId': inviterId,
          'role': 'user',
          'timestamp': ServerValue.timestamp,
        }));
      }
      await Future.wait(invitationFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Environment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, envId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating environment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _canSubmit {
    return !_isLoading &&
      _nameController.text.trim().length >= 3 &&
      (_coAdminId != null || _selectedUserIds.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Environment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _canSubmit ? _createEnvironment : null,
            tooltip: 'Create Environment',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Admin Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Environment Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                      ),
                      title: Text(_currentUserName ?? 'Loading...'),
                      subtitle: Text(_currentUserEmail ?? 'Loading...'),
                      trailing: const Chip(
                        label: Text('Admin'),
                        backgroundColor: Colors.blue,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Environment Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Environment Name',
                hintText: 'Enter a descriptive name for your environment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.domain),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an environment name';
                }
                if (value.length < 3) {
                  return 'Environment name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Co-Admin Selection
            const Text(
              'Select Co-Admin (by email)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _coAdminController,
                        decoration: InputDecoration(
                          labelText: 'Co-Admin Email',
                          hintText: 'Type to search users by email',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_search),
                          suffixIcon: _coAdminId != null
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _removeCoAdmin,
                                )
                              : null,
                        ),
                        onChanged: _onCoAdminChanged,
                        readOnly: _coAdminId != null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_coAdminController.text.trim().isEmpty || _coAdminId != null)
                          ? null
                          : _onCoAdminSearchButton,
                      child: const Icon(Icons.search),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (_coAdminId != null && _coAdminUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        InputChip(
                          label: Text(_coAdminUser!['email'] ?? ''),
                          avatar: const Icon(Icons.admin_panel_settings, size: 20),
                          onDeleted: _removeCoAdmin,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_coAdminSuggestions.isNotEmpty && _coAdminId == null)
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _coAdminSuggestions.length,
                  itemBuilder: (context, index) {
                    final user = _coAdminSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user['name'] ?? 'Anonymous'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () => _selectCoAdmin(user),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            // Users Selection
            const Text(
              'Add Users (by email)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _userController,
                        decoration: InputDecoration(
                          labelText: 'User Email',
                          hintText: 'Type to search users by email',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_add_alt_1),
                        ),
                        onChanged: _onUserChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _userController.text.trim().isEmpty
                          ? null
                          : _onUserSearchButton,
                      child: const Icon(Icons.search),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (_selectedUserIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      children: _selectedUserIds.map((userId) {
                        final user = _selectedUsers[userId]!;
                        return InputChip(
                          label: Text(user['email'] ?? ''),
                          avatar: const Icon(Icons.person, size: 20),
                          onDeleted: () => _removeUser(userId),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            if (_userSuggestions.isNotEmpty)
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _userSuggestions.length,
                  itemBuilder: (context, index) {
                    final user = _userSuggestions[index];
                    final userId = user['id'] as String;
                    final alreadySelected = _selectedUserIds.contains(userId) || userId == _coAdminId;
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user['name'] ?? 'Anonymous'),
                      subtitle: Text(user['email'] ?? ''),
                      enabled: !alreadySelected,
                      onTap: alreadySelected ? null : () => _addUser(user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
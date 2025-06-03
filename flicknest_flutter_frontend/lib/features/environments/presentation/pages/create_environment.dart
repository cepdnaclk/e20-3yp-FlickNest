import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../styles/colors.dart';

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
      
      // Create environment with only admin in users section
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
      await newEnvRef.set(envData);

      // Add environment reference to admin's data with simplified format
      await FirebaseDatabase.instance
        .ref('users/${currentUser.uid}/environments/$envId')
        .set('admin');

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
      
      // Wait for all invitations to be created
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
    return !_isLoading && _nameController.text.trim().length >= 3;
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Environment Name
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.domain,
                        size: 48,
                        color: HomeAutomationColors.darkPrimary,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Environment Name',
                          hintText: 'Enter a descriptive name',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white10,
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
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Info Card
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Environment Admin',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                              ),
                              title: Text(_currentUserName ?? 'Loading...'),
                              subtitle: Text(_currentUserEmail ?? 'Loading...'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Co-Admin Section
                    Text(
                      'Select Co-Admin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _coAdminController,
                                    decoration: InputDecoration(
                                      labelText: 'Co-Admin Email',
                                      hintText: 'Search by email',
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
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(Icons.search),
                                ),
                              ],
                            ),
                            if (_coAdminId != null && _coAdminUser != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.security, color: Colors.teal, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _coAdminUser!['email'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: _removeCoAdmin,
                                        color: Colors.teal,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_coAdminSuggestions.isNotEmpty && _coAdminId == null)
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.2),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _coAdminSuggestions.length,
                          itemBuilder: (context, index) {
                            final user = _coAdminSuggestions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withOpacity(0.1),
                                child: const Icon(Icons.person_outline, color: Colors.teal, size: 20),
                              ),
                              title: Text(user['name'] ?? 'Anonymous'),
                              subtitle: Text(user['email'] ?? ''),
                              onTap: () => _selectCoAdmin(user),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Users Section
                    Text(
                      'Add Users',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _userController,
                                    decoration: const InputDecoration(
                                      labelText: 'User Email',
                                      hintText: 'Search by email',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_add_alt_1),
                                    ),
                                    onChanged: _onUserChanged,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _userController.text.trim().isEmpty
                                      ? null
                                      : _onUserSearchButton,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(Icons.search),
                                ),
                              ],
                            ),
                            if (_selectedUserIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: _selectedUserIds.map((userId) {
                                    final user = _selectedUsers[userId]!;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              user['email'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 20),
                                            onPressed: () => _removeUser(userId),
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_userSuggestions.isNotEmpty)
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.2),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _userSuggestions.length,
                          itemBuilder: (context, index) {
                            final user = _userSuggestions[index];
                            final userId = user['id'] as String;
                            final alreadySelected = _selectedUserIds.contains(userId) || userId == _coAdminId;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.withOpacity(0.1),
                                child: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                              ),
                              title: Text(user['name'] ?? 'Anonymous'),
                              subtitle: Text(user['email'] ?? ''),
                              enabled: !alreadySelected,
                              onTap: alreadySelected ? null : () => _addUser(user),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

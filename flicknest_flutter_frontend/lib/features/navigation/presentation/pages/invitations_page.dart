import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class InvitationsPage extends StatefulWidget {
  static const String route = '/invitations';
  const InvitationsPage({Key? key}) : super(key: key);

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  List<Map<String, dynamic>> invitations = [];
  bool isLoading = true;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    if (currentUser == null) return;
    final ref = FirebaseDatabase.instance.ref('users/${currentUser!.uid}/invitations');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        invitations = [];
        isLoading = false;
      });
      return;
    }
    final data = snapshot.value as Map;
    final List<Map<String, dynamic>> invs = data.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map);
      v['id'] = e.key;
      return v;
    }).toList();
    setState(() {
      invitations = invs;
      isLoading = false;
    });
  }

  void _acceptInvitation(String invitationId) async {
    // TODO: Implement accept logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted invitation.')));
  }

  void _declineInvitation(String invitationId) async {
    // TODO: Implement decline logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Declined invitation.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invitations.isEmpty
              ? const Center(child: Text('No invitations.'))
              : ListView.builder(
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final inv = invitations[index];
                    return Card(
                      child: ListTile(
                        title: Text(inv['environmentName'] ?? 'Unknown Environment'),
                        subtitle: Text('Role: ${inv['role'] ?? ''}'),
                        onTap: () {
                          Navigator.of(context).pushNamed('/invitation-details', arguments: inv);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _acceptInvitation(inv['id']),
                              child: const Text('Accept'),
                            ),
                            TextButton(
                              onPressed: () => _declineInvitation(inv['id']),
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 
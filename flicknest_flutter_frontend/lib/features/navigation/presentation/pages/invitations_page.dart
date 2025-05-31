import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_automation_appbar.dart';
import '../widgets/home_automation_bottombar.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const HomeAutomationAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withAlpha(13),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : invitations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Invitations',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have no pending invitations',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final inv = invitations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(26),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push(
                                '/invitation-details',
                                extra: inv,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withAlpha(12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          inv['role'] == 'co-admin' 
                                              ? Icons.admin_panel_settings
                                              : Icons.person_outline,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              inv['environmentName'] ?? 'Unknown Environment',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Role: ${inv['role'] ?? ''}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _declineInvitation(inv['id']),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.error,
                                          side: BorderSide(color: theme.colorScheme.error),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _acceptInvitation(inv['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const HomeAutomationBottomBar(),
    );
  }
} 
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
    if (currentUser == null) return;
    
    // Remove invitation from UI immediately
    final invitationIndex = invitations.indexWhere((inv) => inv['id'] == invitationId);
    if (invitationIndex == -1) return;

    final invitation = invitations[invitationIndex];
    setState(() {
      invitations.removeAt(invitationIndex);
    });

    try {
      // Get the invitation data
      final invitationRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}/invitations/$invitationId');
      final snapshot = await invitationRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Invitation not found');
      }
      
      final invData = Map<String, dynamic>.from(snapshot.value as Map);
      final environmentId = invData['environmentId'] as String;
      final role = invData['role'] as String;
      
      // Add user to environment with simplified format
      await FirebaseDatabase.instance
        .ref('users/${currentUser!.uid}/environments/$environmentId')
        .set(role);

      // Add user to environment's users list
      await FirebaseDatabase.instance
        .ref('environments/$environmentId/users/${currentUser!.uid}')
        .set({
          'addedAt': ServerValue.timestamp,
          'email': currentUser!.email,
          'name': currentUser!.displayName ?? 'Anonymous',
          'role': role
        });
        
      // Delete the invitation
      await invitationRef.remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully accepted invitation'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home to refresh the environment list
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        // Revert the UI change if there was an error
        setState(() {
          invitations.insert(invitationIndex, invitation);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _declineInvitation(String invitationId) async {
    if (currentUser == null) return;
    
    // Remove invitation from UI immediately
    final invitationIndex = invitations.indexWhere((inv) => inv['id'] == invitationId);
    if (invitationIndex == -1) return;

    final invitation = invitations[invitationIndex];
    setState(() {
      invitations.removeAt(invitationIndex);
    });

    try {
      // Simply delete the invitation
      await FirebaseDatabase.instance
        .ref('users/${currentUser!.uid}/invitations/$invitationId')
        .remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert the UI change if there was an error
        setState(() {
          invitations.insert(invitationIndex, invitation);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              theme.colorScheme.primaryContainer.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : invitations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mail_outline,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Invitations',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have no pending invitations',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final inv = invitations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          elevation: 4,
                          shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              context.push(
                                '/invitation-details',
                                extra: inv,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          inv['role'] == 'co-admin' 
                                              ? Icons.admin_panel_settings
                                              : Icons.person_outline,
                                          color: theme.colorScheme.primary,
                                          size: 28,
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
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Role: ${inv['role'] ?? ''}',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _declineInvitation(inv['id']),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.error,
                                          side: BorderSide(
                                            color: theme.colorScheme.error.withOpacity(0.5),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Decline',
                                          style: theme.textTheme.labelLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _acceptInvitation(inv['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          elevation: 2,
                                          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Accept',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
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


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/home_automation_appbar.dart';
import '../widgets/home_automation_bottombar.dart';
import 'package:go_router/go_router.dart';

class InvitationDetailsPage extends StatelessWidget {
  static const String route = '/invitation-details';
  final Map<String, dynamic>? invitation;
  const InvitationDetailsPage({Key? key, this.invitation}) : super(key: key);

  Future<void> _acceptInvitation(BuildContext context, Map<String, dynamic> inv) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      // Get the invitation data
      final invitationId = inv['id'] as String;
      final environmentId = inv['environmentId'] as String;
      final role = inv['role'] as String;
      
      // Add user to environment with simplified format
      await FirebaseDatabase.instance
        .ref('users/${currentUser.uid}/environments/$environmentId')
        .set(role);

      // Add user to environment's users list
      await FirebaseDatabase.instance
        .ref('environments/$environmentId/users/${currentUser.uid}')
        .set({
          'addedAt': ServerValue.timestamp,
          'email': currentUser.email,
          'name': currentUser.displayName ?? 'Anonymous',
          'role': role
        });
        
      // Delete the invitation
      await FirebaseDatabase.instance
        .ref('users/${currentUser.uid}/invitations/$invitationId')
        .remove();
      
      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(BuildContext context, Map<String, dynamic> inv) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      final invitationId = inv['id'] as String;
      
      // Simply delete the invitation
      await FirebaseDatabase.instance
        .ref('users/${currentUser.uid}/invitations/$invitationId')
        .remove();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
        // Navigate back or to home
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
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
    final inv = invitation ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
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
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(26),
                      ),
                    ),
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
                                  color: theme.colorScheme.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  inv['role'] == 'co-admin' 
                                      ? Icons.admin_panel_settings
                                      : Icons.person_outline,
                                  color: theme.colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inv['environmentName'] ?? 'Unknown Environment',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withAlpha(26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        inv['role'] ?? '',
                                        style: theme.textTheme.bodyMedium?.copyWith(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(26),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invitation Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            'Invited by',
                            inv['inviterId'] ?? '',
                            Icons.person_outline,
                          ),
                          if (inv['timestamp'] != null) ...[
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              context,
                              'Sent at',
                              DateTime.fromMillisecondsSinceEpoch(
                                (inv['timestamp'] is int 
                                    ? inv['timestamp'] 
                                    : int.tryParse(inv['timestamp'].toString()) ?? 0)
                              ).toString(),
                              Icons.access_time,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _declineInvitation(context, inv),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptInvitation(context, inv),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const HomeAutomationBottomBar(),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 
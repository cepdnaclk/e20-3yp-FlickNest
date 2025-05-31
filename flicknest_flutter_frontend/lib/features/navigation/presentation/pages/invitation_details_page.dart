import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class InvitationDetailsPage extends StatelessWidget {
  static const String route = '/invitation-details';
  final Map<String, dynamic>? invitation;
  const InvitationDetailsPage({Key? key, this.invitation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inv = invitation ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Environment: ${inv['environmentName'] ?? ''}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Role: ${inv['role'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Invited by: ${inv['inviterId'] ?? ''}'),
            const SizedBox(height: 8),
            if (inv['timestamp'] != null)
              Text('At: ${DateTime.fromMillisecondsSinceEpoch((inv['timestamp'] is int ? inv['timestamp'] : int.tryParse(inv['timestamp'].toString()) ?? 0))}'),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Accept logic
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted invitation.')));
                  },
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Decline logic
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Declined invitation.')));
                  },
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
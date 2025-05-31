import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../styles/styles.dart';
import '../../../../helpers/utils.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  static const String route = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                GoRouter.of(Utils.mainNav.currentContext!).go(LoginPage.route);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: HomeAutomationStyles.mediumPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            // User Name
            Text(
              currentUser?.displayName ?? 'Anonymous User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            // Email
            Text(
              currentUser?.email ?? 'No email',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            // Additional user information can be added here
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Verified'),
              trailing: Icon(
                currentUser?.emailVerified == true
                    ? Icons.check_circle
                    : Icons.cancel,
                color: currentUser?.emailVerified == true
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Last Sign In'),
              subtitle: Text(
                currentUser?.metadata.lastSignInTime?.toString() ??
                    'Not available',
              ),
            ),
            const Spacer(),
            // Delete Account Button
            ElevatedButton(
              onPressed: () {
                // Show confirmation dialog before deleting account
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                      'Are you sure you want to delete your account? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await currentUser?.delete();
                            if (context.mounted) {
                              GoRouter.of(Utils.mainNav.currentContext!).go(LoginPage.route);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting account: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 
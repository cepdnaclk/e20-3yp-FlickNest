import 'package:flicknest_flutter_frontend/features/shared/widgets/flicky_animated_icons.dart';
import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../profile/presentation/pages/profile.page.dart';
import '../../../../helpers/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeAutomationAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAutomationAppBar({super.key});

  @override
  State<HomeAutomationAppBar> createState() => _HomeAutomationAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(HomeAutomationStyles.appBarSize);
}

class _HomeAutomationAppBarState extends State<HomeAutomationAppBar> {
  int notificationCount = 0;
  List<Map<String, dynamic>> invitations = [];
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
        notificationCount = 0;
      });
      return;
    }
    final data = snapshot.value as Map;
    final List<Map<String, dynamic>> invs = data.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map);
      v['id'] = e.key;
      return v;
    })
    // Only show unread invitations
    .where((inv) => inv['markasread'] != true)
    .toList();
    setState(() {
      invitations = invs;
      notificationCount = invs.length;
    });
  }

  Future<String> _getUsername(String inviterId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$inviterId');
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
          return data['name'];
        }
        if (data['email'] != null) {
          return data['email'];
        }
      }
    } catch (_) {}
    return inviterId;
  }

  void _markInvitationAsRead(String invitationId) async {
    if (currentUser == null) return;
    final ref = FirebaseDatabase.instance.ref('users/${currentUser!.uid}/invitations/$invitationId/markasread');
    await ref.set(true);
    setState(() {
      invitations.removeWhere((inv) => inv['id'] == invitationId);
      notificationCount = invitations.length;
    });
  }

  void _showInvitationsSheet(BuildContext context) async {
    await _fetchInvitations();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        if (invitations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No invitations.')),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invitations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...invitations.map((inv) => Card(
                child: ListTile(
                  leading: Icon(
                    inv['role'] == 'co-admin' ? Icons.admin_panel_settings : Icons.person,
                  ),
                  title: Text(inv['environmentName'] ?? 'Unknown Environment'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${inv['role']}'),
                      Text('Invited by: ${inv['inviterId']}'),
                      if (inv['timestamp'] != null)
                        Text('At: ${DateTime.fromMillisecondsSinceEpoch(
                          (inv['timestamp'] is int ? inv['timestamp'] : int.tryParse(inv['timestamp'].toString()) ?? 0))}')
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationOffCanvas(BuildContext context) async {
    await _fetchInvitations();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Notifications",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              color: Theme.of(context).canvasColor,
              child: SafeArea(
                child: invitations.isEmpty
                    ? const Center(child: Text('No invitations.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Invitations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...invitations.map((inv) => FutureBuilder<String>(
                                future: _getUsername(inv['inviterId']),
                                builder: (context, snapshot) {
                                  final username = snapshot.data ?? inv['inviterId'];
                                  final role = inv['role'] ?? '';
                                  final envName = inv['environmentName'] ?? '';
                                  final isRead = inv['markasread'] == true;
                                  return Card(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          '/invitation-details',
                                          arguments: inv,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(role == 'co-admin' ? Icons.admin_panel_settings : Icons.person),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '$username sent you a request for $role in $envName',
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (inv['timestamp'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  'At: ${DateTime.fromMillisecondsSinceEpoch((inv['timestamp'] is int ? inv['timestamp'] : int.tryParse(inv['timestamp'].toString()) ?? 0))}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 300),
                                                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                                  child: isRead
                                                      ? const Icon(Icons.check_circle, color: Colors.green, key: ValueKey('tick'))
                                                      : TextButton(
                                                          key: const ValueKey('markasread'),
                                                          onPressed: () => _markInvitationAsRead(inv['id']),
                                                          child: const Text('Mark as read'),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final width = MediaQuery.of(context).size.width * 0.8;
        final offsetX = width * (1 - animation.value);
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: child,
        );
      },
    );
  }

  Widget _buildProfileIcon() {
    if (currentUser?.photoURL != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(currentUser!.photoURL!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return const Icon(Icons.account_circle_outlined);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.secondary,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const FlickyAnimatedIcons(
        icon: FlickyAnimatedIconOptions.flickybulb,
        isSelected: true,
      ),
      centerTitle: true,
      actions: [
        // Profile Icon
        IconButton(
          icon: _buildProfileIcon(),
          onPressed: () {
            GoRouter.of(context).go(ProfilePage.route);
          },
        ),
        HomeAutomationStyles.xxsmallHGap,

        // Notification Icon with Badge
        Builder(
          builder: (context) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  _showNotificationOffCanvas(context);
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        HomeAutomationStyles.xxsmallHGap,
      ],
    );
  }
}
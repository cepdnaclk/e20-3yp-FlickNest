import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';

class UserDeviceAccessPage extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  const UserDeviceAccessPage({required this.userId, required this.userName, Key? key}) : super(key: key);

  @override
  ConsumerState<UserDeviceAccessPage> createState() => _UserDeviceAccessPageState();
}

class _UserDeviceAccessPageState extends ConsumerState<UserDeviceAccessPage> {
  Map<String, dynamic> _rooms = {};
  Map<String, dynamic> _devices = {};
  bool _loading = true;
  Map<String, bool> _expandedRooms = {};
  bool _showAllDevices = true;

  // Device type icons mapping (copied from devices.page.dart for consistency)
  final Map<String, IconData> _deviceIcons = {
    'L': Icons.lightbulb_outline,
    'F': Icons.wind_power,
    'TV': Icons.tv,
    'C': Icons.camera_outdoor,
    'MS': Icons.sensor_door,
    'B': Icons.bathroom,
    'E': Icons.electrical_services,
    'DB': Icons.doorbell,
    'K': Icons.kitchen,
    'R': Icons.router,
    'BL': Icons.blinds,
    'AC': Icons.ac_unit,
    'GL': Icons.garage,
    'GD': Icons.door_sliding,
  };

  IconData _getDeviceIcon(String? symbol) {
    if (symbol == null) return Icons.devices_other;
    String prefix = symbol.replaceAll(RegExp(r'[0-9]'), '');
    if (prefix.isEmpty) return Icons.devices_other;
    return _deviceIcons[prefix] ?? Icons.devices_other;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final envId = ref.read(currentEnvironmentProvider);
    if (envId == null) return;

    try {
      final roomsRef = FirebaseDatabase.instance.ref('environments/$envId/rooms');
      final devicesRef = FirebaseDatabase.instance.ref('environments/$envId/devices');
      final roomsSnap = await roomsRef.get();
      final devicesSnap = await devicesRef.get();

      if (mounted) {
        setState(() {
          _rooms = roomsSnap.exists ? Map<String, dynamic>.from(roomsSnap.value as Map) : {};
          _devices = devicesSnap.exists ? Map<String, dynamic>.from(devicesSnap.value as Map) : {};
          _loading = false;
          _expandedRooms = Map.fromEntries(_rooms.keys.map((key) => MapEntry(key, true)));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAccess(String deviceId, bool giveAccess) async {
    final envId = ref.read(currentEnvironmentProvider);
    if (envId == null) return;

    try {
      final deviceRef = FirebaseDatabase.instance.ref('environments/$envId/devices/$deviceId/allowedUsers');
      if (giveAccess) {
        await deviceRef.update({widget.userId: true});
        _showFeedback(true, 'Access granted');
      } else {
        await deviceRef.child(widget.userId).remove();
        _showFeedback(false, 'Access revoked');
      }
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating access: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showFeedback(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        width: 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: _buildAppBar(theme),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading devices...'),
            ],
          ),
        ),
      );
    }

    // Process data
    Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
    List<Map<String, dynamic>> unassignedDevices = [];

    _devices.forEach((deviceId, deviceData) {
      final device = Map<String, dynamic>.from(deviceData as Map);
      final deviceWithId = {'id': deviceId, ...device};
      final allowedUsers = device['allowedUsers'] != null
          ? Map<String, dynamic>.from(device['allowedUsers'] as Map)
          : <String, dynamic>{};

      final hasAccess = allowedUsers.containsKey(widget.userId);
      if (_showAllDevices || hasAccess) {
        final roomId = device['roomId'] as String? ?? '';
        if (roomId.isEmpty) {
          unassignedDevices.add(deviceWithId);
        } else {
          devicesByRoom.putIfAbsent(roomId, () => []);
          devicesByRoom[roomId]!.add(deviceWithId);
        }
      }
    });

    if (devicesByRoom.isEmpty && unassignedDevices.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(theme),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_other,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _showAllDevices
                    ? "No devices found in this environment"
                    : "No accessible devices found",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              Text(
                _showAllDevices
                    ? "Add some devices to get started"
                    : "This user doesn't have access to any devices yet",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_showAllDevices) ...[
                    TextButton.icon(
                      onPressed: () => setState(() => _showAllDevices = true),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Show all devices'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Build the list of widgets for all sections
    List<Widget> children = [
      // Header section
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showAllDevices ? 'All Devices' : 'Accessible Devices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _showAllDevices
                        ? 'Toggle switches to manage access'
                        : 'Showing devices this user can access',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showAllDevices = !_showAllDevices),
              icon: Icon(_showAllDevices ? Icons.visibility_outlined : Icons.visibility),
              label: Text(_showAllDevices ? 'Show accessible' : 'Show all'),
            ),
          ],
        ),
      ),
    ];

    // Add unassigned devices section
    if (unassignedDevices.isNotEmpty) {
      children.add(
        _buildDevicesSection(
          "Unassigned Devices",
          unassignedDevices,
          null,
          theme,
          icon: Icons.devices_other,
        ),
      );
    }

    // Add room sections
    devicesByRoom.forEach((roomId, devices) {
      final roomName = _rooms[roomId]?['name'] ?? 'Unknown Room';
      children.add(
        _buildDevicesSection(
          roomName,
          devices,
          roomId,
          theme,
          icon: Icons.room_preferences,
        ),
      );
    });

    // Add bottom padding
    children.add(const SizedBox(height: 80));

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onBackground,
      title: Row(
        children: [
          // Removed Hero widget to avoid duplicate tag issues
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Access',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: theme.colorScheme.onBackground),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Search coming soon!'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(8),
              ),
            );
          },
          tooltip: 'Search devices',
        ),
      ],
    );
  }

  Widget _buildDevicesSection(String title, List<Map<String, dynamic>> devices, String? roomId, ThemeData theme, {IconData icon = Icons.devices_other}) {
    final isExpanded = _expandedRooms[roomId] ?? true;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: roomId == null ? null : () {
                    setState(() => _expandedRooms[roomId] = !isExpanded);
                  },
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${devices.length} device${devices.length == 1 ? '' : 's'}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (roomId != null)
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: AnimatedCrossFade(
                  firstChild: const SizedBox(height: 0),
                  secondChild: Column(
                    children: [
                      const Divider(height: 1),
                      ...devices.map((device) {
                        final allowedUsers = device['allowedUsers'] != null
                            ? Map<String, dynamic>.from(device['allowedUsers'] as Map)
                            : <String, dynamic>{};
                        final hasAccess = allowedUsers.containsKey(widget.userId);
                        return _buildDeviceAccessTile(device, roomId, hasAccess, theme);
                      }),
                    ],
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOutCubic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceAccessTile(Map<String, dynamic> device, String? roomId, bool hasAccess, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: hasAccess
                ? theme.colorScheme.primary.withOpacity(0.05)
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAccess
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: 'device_${device['id']}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAccess
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (hasAccess)
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  _getDeviceIcon(device['symbol']),
                  color: hasAccess
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              device['name'] ?? 'Unknown Device',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground,
                fontWeight: hasAccess ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              'ID: ${device['id']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: hasAccess,
                onChanged: (val) => _toggleAccess(device['id'], val),
                activeColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


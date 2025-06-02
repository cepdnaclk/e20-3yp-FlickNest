import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RoomDetailsPage extends StatefulWidget {
  static const String route = '/room-details';
  final String environmentId;
  final String roomId;
  final String roomName;

  const RoomDetailsPage({
    Key? key,
    required this.environmentId,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  Map<String, dynamic> devices = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      // Get all devices in the room
      final roomDevicesRef = FirebaseDatabase.instance
          .ref('environments/${widget.environmentId}/rooms/${widget.roomId}/devices');
      final roomDevicesSnapshot = await roomDevicesRef.get();
      
      if (!roomDevicesSnapshot.exists) {
        setState(() {
          devices = {};
          isLoading = false;
        });
        return;
      }

      final roomDevices = Map<String, dynamic>.from(roomDevicesSnapshot.value as Map);
      final Map<String, dynamic> deviceDetails = {};

      // Fetch details for each device
      for (final deviceId in roomDevices.keys) {
        final deviceRef = FirebaseDatabase.instance
            .ref('environments/${widget.environmentId}/devices/$deviceId');
        final deviceSnapshot = await deviceRef.get();
        
        if (deviceSnapshot.exists) {
          deviceDetails[deviceId] = deviceSnapshot.value;
        }
      }

      if (mounted) {
        setState(() {
          devices = deviceDetails;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching devices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDeviceState(String deviceId, bool currentState) async {
    try {
      final newState = !currentState;
      await FirebaseDatabase.instance
          .ref('environments/${widget.environmentId}/devices/$deviceId/state')
          .set(newState);

      setState(() {
        devices[deviceId]['state'] = newState;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling device state: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices_other,
                        size: 64,
                        color: theme.colorScheme.primary.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Devices',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This room has no devices yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final deviceId = devices.keys.elementAt(index);
                    final device = devices[deviceId];
                    final bool isDeviceOn = device['state'] ?? false;
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withAlpha(26),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device['name'] ?? 'Unknown Device',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Symbol: ${device['assignedSymbol'] ?? 'None'}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isDeviceOn,
                                  onChanged: (value) => _toggleDeviceState(deviceId, isDeviceOn),
                                ),
                              ],
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
import 'package:flutter/material.dart';
import '../../../../constants.dart';
import 'device_card.dart';

class RoomCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> roomData;
  final bool isExpanded;
  final List<String> roomList;
  final Map<String, dynamic> devicesByRoom;
  final Function(String) onRoomExpandToggle;
  final Function(String, String, bool, String?) onToggleDevice;
  final Function(String, Map<String, dynamic>, String?) onMoveDevice;

  const RoomCard({
    Key? key,
    required this.roomId,
    required this.roomData,
    required this.isExpanded,
    required this.roomList,
    required this.devicesByRoom,
    required this.onRoomExpandToggle,
    required this.onToggleDevice,
    required this.onMoveDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String roomName = roomData["name"] ?? AppConstants.defaultRoomName;
    // Cast the devices map properly
    final dynamic devicesData = roomData["devices"] ?? {};
    final Map<String, dynamic> devices = Map<String, dynamic>.from(devicesData);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => onRoomExpandToggle(roomId),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.room_preferences, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        roomName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      AppConstants.deviceCountLabel.replaceAll('{0}', devices.length.toString()),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, deviceIndex) {
                  final deviceEntry = devices.entries.elementAt(deviceIndex);
                  return DeviceCard(
                    deviceId: deviceEntry.key,
                    deviceData: deviceEntry.value,
                    currentRoomId: roomId,
                    roomList: roomList,
                    devicesByRoom: devicesByRoom,
                    onToggleDevice: onToggleDevice,
                    onMoveDevice: onMoveDevice,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

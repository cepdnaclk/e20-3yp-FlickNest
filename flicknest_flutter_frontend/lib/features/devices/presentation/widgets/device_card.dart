import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants.dart';
import '../../../../providers/role/role_provider.dart';
import '../utils/device_icon_mapper.dart';

class DeviceCard extends ConsumerWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;
  final String? currentRoomId;
  final List<String> roomList;
  final Map<String, dynamic> devicesByRoom;
  final Function(String, String, bool, String?) onToggleDevice;
  final Function(String, Map<String, dynamic>, String?) onMoveDevice;

  const DeviceCard({
    Key? key,
    required this.deviceId,
    required this.deviceData,
    required this.currentRoomId,
    required this.roomList,
    required this.devicesByRoom,
    required this.onToggleDevice,
    required this.onMoveDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool deviceState = deviceData["state"] ?? false;
    final String symbol = deviceData["symbol"] ?? "";
    final String deviceName = deviceData["name"] ?? AppConstants.defaultDeviceName;
    final roleAsync = ref.watch(currentUserRoleProvider);
    final isAdmin = roleAsync.asData?.value == 'admin';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: deviceState
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              DeviceIconMapper.getDeviceIcon(symbol),
              color: deviceState
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(deviceName, style: theme.textTheme.titleMedium),
          subtitle: Text(
            deviceState ? AppConstants.deviceStateOn : AppConstants.deviceStateOff,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: deviceState
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: deviceState,
                onChanged: (bool newValue) {
                  onToggleDevice(deviceId, deviceData["assignedSymbol"], newValue, currentRoomId);
                },
                activeColor: theme.colorScheme.primary,
              ),
              if (isAdmin)
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String? targetRoomId) {
                    onMoveDevice(deviceId, deviceData, targetRoomId);
                  },
                  itemBuilder: (BuildContext context) => [
                    if (currentRoomId != null)
                      PopupMenuItem<String?>(
                        value: null,
                        child: Text(AppConstants.moveToUnassignedLabel),
                      ),
                    ...roomList
                        .where((roomId) => roomId != currentRoomId)
                        .map((roomId) => PopupMenuItem<String>(
                          value: roomId,
                          child: Text(AppConstants.moveToRoomLabel
                              .replaceAll('{0}', devicesByRoom[roomId]["name"])),
                        ))
                        .toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

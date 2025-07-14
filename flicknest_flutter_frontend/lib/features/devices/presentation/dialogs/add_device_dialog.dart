import 'package:flutter/material.dart';
import '../../../../constants.dart';
import '../utils/device_icon_mapper.dart';
import '../../services/device_operations_service.dart';

class AddDeviceDialog extends StatefulWidget {
  final String? environmentId;
  final List<Map<String, String>> availableSymbols;
  final List<String> roomList;
  final Map<String, dynamic> devicesByRoom;

  const AddDeviceDialog({
    Key? key,
    required this.environmentId,
    required this.availableSymbols,
    required this.roomList,
    required this.devicesByRoom,
  }) : super(key: key);

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  String deviceName = "";
  String? selectedSymbol;
  String? selectedRoom;
  late final DeviceOperationsService _deviceOpsService;

  _AddDeviceDialogState() : _deviceOpsService = DeviceOperationsService(null);

  @override
  void initState() {
    super.initState();
    _deviceOpsService = DeviceOperationsService(widget.environmentId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(AppConstants.addDeviceTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: AppConstants.deviceNameLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.device_hub),
                filled: true,
              ),
              onChanged: (value) => deviceName = value,
            ),
            const SizedBox(height: 16),
            if (widget.availableSymbols.isEmpty)
              _buildNoSymbolsMessage()
            else
              _buildSymbolDropdown(),
            const SizedBox(height: 16),
            if (widget.roomList.isEmpty)
              _buildNoRoomsMessage()
            else
              _buildRoomDropdown(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppConstants.cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _handleAddDevice,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(AppConstants.addDeviceButtonLabel),
        ),
      ],
    );
  }

  Widget _buildNoSymbolsMessage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        AppConstants.noSymbolsMessage,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildNoRoomsMessage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        AppConstants.noRoomsMessage,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildSymbolDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSymbol,
      decoration: InputDecoration(
        labelText: AppConstants.deviceTypeLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.category),
        filled: true,
      ),
      onChanged: (String? newValue) {
        setState(() => selectedSymbol = newValue);
      },
      items: widget.availableSymbols
          .where((symbolData) =>
              symbolData['id'] != null && symbolData['id']!.isNotEmpty)
          .map((symbolData) {
            final symbolId = symbolData['id']!;
            final symbolName = symbolData['name'] ?? symbolId;
            return DropdownMenuItem<String>(
              value: symbolId,
              child: Row(
                children: [
                  Icon(DeviceIconMapper.getDeviceIcon(symbolId)),
                  const SizedBox(width: 12),
                  Text(symbolName),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildRoomDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRoom,
      decoration: InputDecoration(
        labelText: AppConstants.selectRoomLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.room_preferences),
        filled: true,
      ),
      onChanged: (value) {
        setState(() => selectedRoom = value);
      },
      items: widget.roomList.map((roomId) {
        return DropdownMenuItem<String>(
          value: roomId,
          child: Text(widget.devicesByRoom[roomId]["name"]),
        );
      }).toList(),
    );
  }

  void _handleAddDevice() async {
    if (deviceName.isEmpty) {
      _showError(AppConstants.noDeviceNameError);
      return;
    }
    if (selectedSymbol == null) {
      _showError(AppConstants.noDeviceTypeError);
      return;
    }

    try {
      await _deviceOpsService.addDevice(
        deviceName,
        selectedSymbol!,
        selectedRoom,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.deviceAddedSuccess.replaceAll('{0}', deviceName)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError(AppConstants.deviceAddError.replaceAll('{0}', e.toString()));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../constants.dart';

class DeviceIconMapper {
  static IconData getDeviceIcon(String symbol) {
    // Extract the prefix (remove numbers)
    String prefix = symbol.replaceAll(RegExp(r'[0-9]'), '');

    // If the prefix is empty or not found in the map, return default icon
    if (prefix.isEmpty) {
      return Icons.devices_other;
    }

    return _getIconDataFromString(AppConstants.deviceTypeIcons[prefix] ?? 'devices_other');
  }

  static IconData _getIconDataFromString(String iconName) {
    switch (iconName) {
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'wind_power':
        return Icons.wind_power;
      case 'tv':
        return Icons.tv;
      case 'camera_outdoor':
        return Icons.camera_outdoor;
      case 'sensor_door':
        return Icons.sensor_door;
      case 'bathroom':
        return Icons.bathroom;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'doorbell':
        return Icons.doorbell;
      case 'kitchen':
        return Icons.kitchen;
      case 'router':
        return Icons.router;
      case 'blinds':
        return Icons.blinds;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'garage':
        return Icons.garage;
      case 'door_sliding':
        return Icons.door_sliding;
      default:
        return Icons.devices_other;
    }
  }
}

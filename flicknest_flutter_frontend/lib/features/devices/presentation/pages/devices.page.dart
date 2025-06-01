import 'package:flutter/material.dart';
import '../../../../Firebase/switchModel.dart';
import '../../../../Firebase/deviceService.dart';
import 'package:go_router/go_router.dart';

class DevicesPage extends StatefulWidget {
  static const String route = '/devices';
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final SwitchService _switchService = SwitchService();
  final DeviceService _deviceService = DeviceService();

  Map<String, dynamic> _devicesByRoom = {};
  List<String> _availableSymbols = [];
  List<String> _roomList = [];
  bool _loading = true;
  Map<String, bool> _expandedRooms = {};
  List<Map<String, dynamic>> _unassignedDevices = [];

  // Device type icons mapping
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

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _fetchAvailableSymbols();
  }

  /// 🔥 Fetch devices
  void _fetchDevices() async {
    setState(() => _loading = true);
    
    try {
      final devicesDataStream = _switchService.getDevicesByRoomStream();
      final devicesData = await devicesDataStream.first;

      if (mounted) {
        final Map<String, dynamic> processedDevices = {};
        final List<Map<String, dynamic>> unassignedDevs = [];

        // Process devices and organize by room
        devicesData.forEach((roomId, roomData) {
          if (roomId == 'unassigned' || roomData['devices'] == null) {
            if (roomData['devices'] != null) {
              final devices = Map<String, dynamic>.from(roomData['devices']);
              devices.forEach((deviceId, deviceData) {
                unassignedDevs.add({
                  'id': deviceId,
                  ...Map<String, dynamic>.from(deviceData),
                });
              });
            }
          } else {
            processedDevices[roomId] = {
              'name': roomData['name'],
              'devices': Map<String, dynamic>.from(roomData['devices'] ?? {}),
            };
          }
        });

        setState(() {
          _devicesByRoom = processedDevices;
          _roomList = processedDevices.keys.toList();
          _unassignedDevices = unassignedDevs;
          
          // Initialize expanded state for new rooms
          for (var roomId in _roomList) {
            _expandedRooms.putIfAbsent(roomId, () => true);
          }
          
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching devices: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 🔥 Fetch available symbols
  void _fetchAvailableSymbols() async {
    final usedSymbols = await _deviceService.getUsedSymbols();
    final allSymbols = ["L1", "F1", "TV1", "C1", "MS1", "B1", "B2", "E1", "DB1", "K1", "R1", "BL1", "AC1", "GL1", "GD1"];

    setState(() {
      _availableSymbols = allSymbols.where((symbol) => !usedSymbols.contains(symbol)).toList();
    });
  }

  IconData _getDeviceIcon(String symbol) {
    String prefix = symbol.replaceAll(RegExp(r'[0-9]'), '');
    return _deviceIcons[prefix] ?? Icons.devices_other;
  }

  void _showAddDeviceDialog() {
    String deviceName = "";
    String? selectedSymbol;
    String? selectedRoom;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text("Add New Device", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Device Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.device_hub),
                        filled: true,
                      ),
                      onChanged: (value) => deviceName = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSymbol,
                      decoration: InputDecoration(
                        labelText: "Device Type",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category),
                        filled: true,
                      ),
                      onChanged: (String? newValue) {
                        setState(() => selectedSymbol = newValue);
                      },
                      items: _availableSymbols.map((String symbol) {
                        return DropdownMenuItem<String>(
                          value: symbol,
                          child: Row(
                            children: [
                              Icon(_getDeviceIcon(symbol)),
                              const SizedBox(width: 12),
                              Text(symbol),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRoom,
                      decoration: InputDecoration(
                        labelText: "Select Room",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.room_preferences),
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() => selectedRoom = value);
                      },
                      items: _roomList.map((roomId) {
                        return DropdownMenuItem<String>(
                          value: roomId,
                          child: Text(_devicesByRoom[roomId]["name"]),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Device"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    if (deviceName.isNotEmpty && selectedSymbol != null) {
                      _deviceService.addDevice(deviceName, selectedSymbol!, selectedRoom);
                      Navigator.pop(context);
                      _fetchDevices();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _moveDeviceToRoom(String deviceId, Map<String, dynamic> deviceData, String? targetRoomId) async {
    try {
      setState(() {
        if (targetRoomId == null) {
          // Move to unassigned
          _unassignedDevices.add({'id': deviceId, ...deviceData});
          // Remove from current room
          for (var roomId in _devicesByRoom.keys) {
            _devicesByRoom[roomId]['devices'].remove(deviceId);
          }
        } else {
          // Ensure the target room exists in the map
          _devicesByRoom.putIfAbsent(targetRoomId, () => {
            'name': 'New Room',
            'devices': {},
          });

          // Move to target room
          _devicesByRoom[targetRoomId]['devices'][deviceId] = deviceData;
          // Remove from unassigned if it was there
          _unassignedDevices.removeWhere((device) => device['id'] == deviceId);
          // Remove from other rooms
          for (var roomId in _devicesByRoom.keys) {
            if (roomId != targetRoomId) {
              _devicesByRoom[roomId]['devices'].remove(deviceId);
            }
          }
        }
      });

      // Update in backend
      await _deviceService.updateDeviceRoom(deviceId, targetRoomId);
    } catch (e) {
      print('Error moving device: $e');
      // Revert changes on error
      _fetchDevices();
    }
  }

  Widget _buildDeviceCard(String deviceId, Map<String, dynamic> deviceData, String? currentRoomId) {
    final theme = Theme.of(context);
    final bool deviceState = deviceData["state"] ?? false;
    final String symbol = deviceData["symbol"] ?? "";
    final String deviceName = deviceData["name"] ?? "Unknown Device";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: deviceState 
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
            child: Icon(
              _getDeviceIcon(symbol),
              color: deviceState 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(deviceName, style: theme.textTheme.titleMedium),
          subtitle: Text(
            deviceState ? "On" : "Off",
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
                onChanged: (bool newValue) async {
                  try {
                    await _switchService.updateDeviceState(deviceId, newValue);
                    if (mounted) {
                      setState(() {
                        if (currentRoomId != null) {
                          _devicesByRoom[currentRoomId]["devices"][deviceId]["state"] = newValue;
                        } else {
                          final deviceIndex = _unassignedDevices.indexWhere((d) => d['id'] == deviceId);
                          if (deviceIndex != -1) {
                            _unassignedDevices[deviceIndex]['state'] = newValue;
                          }
                        }
                      });
                    }
                  } catch (e) {
                    print('Error updating device state: $e');
                  }
                },
                activeColor: theme.colorScheme.primary,
              ),
              PopupMenuButton<String?>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String? targetRoomId) {
                  _moveDeviceToRoom(deviceId, deviceData, targetRoomId);
                },
                itemBuilder: (BuildContext context) => [
                  if (currentRoomId != null)
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('Move to Unassigned'),
                    ),
                  ..._roomList
                      .where((roomId) => roomId != currentRoomId)
                      .map((roomId) => PopupMenuItem<String>(
                            value: roomId,
                            child: Text('Move to ${_devicesByRoom[roomId]["name"]}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/devices/add'),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Device", style: TextStyle(color: Colors.white)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text("Loading your smart home...", style: theme.textTheme.bodyLarge),
                  ],
                ),
              )
            : _devicesByRoom.isEmpty && _unassignedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          "Welcome to Your Smart Home",
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add your first device to get started",
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Add Device"),
                          onPressed: _showAddDeviceDialog,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (_unassignedDevices.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.devices_other, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Unassigned Devices",
                                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${_unassignedDevices.length} devices",
                                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _unassignedDevices.length,
                                    itemBuilder: (context, index) {
                                      final device = _unassignedDevices[index];
                                      return _buildDeviceCard(device['id'], device, null);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final roomEntry = _devicesByRoom.entries.elementAt(index);
                            final String roomId = roomEntry.key;
                            final Map<String, dynamic> roomData = roomEntry.value;
                            final String roomName = roomData["name"] ?? "Unknown Room";
                            final Map<String, dynamic> devices = roomData["devices"] ?? {};

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _expandedRooms[roomId] = !(_expandedRooms[roomId] ?? true);
                                        });
                                      },
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
                                              "${devices.length} devices",
                                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _expandedRooms[roomId] ?? true ? Icons.expand_less : Icons.expand_more,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_expandedRooms[roomId] ?? true) ...[
                                      const Divider(height: 1),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: devices.length,
                                        itemBuilder: (context, deviceIndex) {
                                          final deviceEntry = devices.entries.elementAt(deviceIndex);
                                          return _buildDeviceCard(deviceEntry.key, deviceEntry.value, roomId);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _devicesByRoom.length,
                        ),
                      ),
                      // Add bottom padding
                      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                    ],
                  ),
      ),
    );
  }
}
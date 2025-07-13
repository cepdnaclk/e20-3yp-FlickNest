import 'package:flutter/material.dart';
import '../../../../Firebase/switchModel.dart';
import '../../../../Firebase/deviceService.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/environment/environment_provider.dart';
import '../../../../providers/role/role_provider.dart';
import '../../../../providers/network/network_mode_provider.dart';
import '../../../../services/local_broker_service.dart';
import '../../../../services/local_websocket_service.dart';
import '../../../../constants.dart';

class DevicesPage extends ConsumerStatefulWidget {
  static const String route = '/devices';
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  late final SwitchService _switchService;
  final DeviceService _deviceService = DeviceService();
  StreamSubscription? _devicesSubscription;
  String? _environmentId;

  Map<String, dynamic> _devicesByRoom = {};
  List<Map<String, String>> _availableSymbols = [];
  List<String> _roomList = [];
  bool _loading = true;
  final Map<String, bool> _expandedRooms = {};
  List<Map<String, dynamic>> _unassignedDevices = [];
  bool _isBrokerOnline = false;
  List<String> updates = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    final envId = ref.read(currentEnvironmentProvider);
    _switchService = SwitchService(envId ?? '');
    _setupDevicesListener();
    _fetchAvailableSymbols();
    _checkBrokerStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _environmentId = ref.read(currentEnvironmentProvider);
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _checkBrokerStatus() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.localBrokerUrl}${AppConstants.healthEndpoint}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && !_isDisposed) {
          setState(() {
            _isBrokerOnline = data['mqtt_connected'] == true;
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _isBrokerOnline = false;
          });
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isBrokerOnline = false;
        });
      }
    }
  }

  /// 🔥 Setup real-time devices listener
  void _setupDevicesListener() {
    setState(() => _loading = true);

    try {
      final devicesDataStream = _switchService.getDevicesByRoomStream();
      _devicesSubscription = devicesDataStream.listen((devicesData) {
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
      }, onError: (error) {
        print('Error in devices stream: $error');
        if (mounted) {
          setState(() => _loading = false);
        }
      });
    } catch (e) {
      print('Error setting up devices listener: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 🔥 Fetch available symbols
  void _fetchAvailableSymbols() async {
    try {
      final symbolsWithNames = await _deviceService.getAvailableSymbolsWithNames();
      if (mounted) {
        setState(() {
          _availableSymbols = symbolsWithNames;
        });
      }
    } catch (e) {
      print('Error fetching available symbols: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.symbolFetchError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getDeviceIcon(String symbol) {
    // Extract the prefix (remove numbers)
    String prefix = symbol.replaceAll(RegExp(r'[0-9]'), '');

    // If the prefix is empty or not found in the map, return default icon
    if (prefix.isEmpty) {
      return Icons.devices_other;
    }

    return _getIconDataFromString(AppConstants.deviceTypeIcons[prefix] ?? 'devices_other');
  }

  IconData _getIconDataFromString(String iconName) {
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

  void _showAddDeviceDialog() {
    if (_environmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.noEnvironmentError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String deviceName = "";
    String? selectedSymbol;
    String? selectedRoom;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: Theme.of(stateContext).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(AppConstants.addDeviceTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    if (_availableSymbols.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppConstants.noSymbolsMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedSymbol,
                        decoration: InputDecoration(
                          labelText: AppConstants.deviceTypeLabel,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category),
                          filled: true,
                        ),
                        onChanged: (String? newValue) {
                          setDialogState(() => selectedSymbol = newValue);
                        },
                        items: _availableSymbols
                          .where((symbolData) =>
                            symbolData['id'] != null &&
                            symbolData['id']!.isNotEmpty)
                          .map((symbolData) {
                            final symbolId = symbolData['id']!;
                            final symbolName = symbolData['name'] ?? symbolId;

                            return DropdownMenuItem<String>(
                              value: symbolId,
                              child: Row(
                                children: [
                                  Icon(_getDeviceIcon(symbolId)),
                                  const SizedBox(width: 12),
                                  Text(symbolName),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      ),
                    const SizedBox(height: 16),
                    if (_roomList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppConstants.noRoomsMessage,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedRoom,
                        decoration: InputDecoration(
                          labelText: AppConstants.selectRoomLabel,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.room_preferences),
                          filled: true,
                        ),
                        onChanged: (value) {
                          setDialogState(() => selectedRoom = value);
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
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppConstants.cancelButtonLabel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (deviceName.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(AppConstants.noDeviceNameError),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (selectedSymbol == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(AppConstants.noDeviceTypeError),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _deviceService.addDevice(
                        deviceName,
                        selectedSymbol!,
                        selectedRoom,
                        environmentId: _environmentId!,
                      );
                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppConstants.deviceAddedSuccess.replaceAll('{0}', deviceName)),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(AppConstants.deviceAddError.replaceAll('{0}', e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(AppConstants.addDeviceButtonLabel),
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
            'name': AppConstants.defaultRoomName,
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
      _setupDevicesListener();
    }
  }

  Future<void> _updateLocalDbSymbol(String symbolKey, bool state) async {
    try {
      final url = Uri.parse('${AppConstants.localBrokerUrl}${AppConstants.symbolsEndpoint}/$symbolKey');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': state}),
      );
      if (response.statusCode == 200) {
        setState(() {
          updates.add('Local DB PATCH success: ${response.body}');
        });
      } else {
        setState(() {
          updates.add('Local DB PATCH failed: ${response.statusCode}');
        });
      }
    } catch (e) {
      setState(() {
        updates.add('Local DB PATCH error: $e');
      });
    }
  }

  Future<void> _updateLocalDbDeviceState(String deviceId, bool newState) async {
    try {
      final file = File('lib/local_db.json');
      final content = await file.readAsString();
      final db = jsonDecode(content);
      // Find the environment and device
      final envs = db['environments'];
      for (final envKey in envs.keys) {
        final env = envs[envKey];
        if (env['devices'] != null && env['devices'][deviceId] != null) {
          env['devices'][deviceId]['state'] = newState;
        }
      }
      await file.writeAsString(jsonEncode(db));
    } catch (e) {
      print('Error updating local_db.json device state: $e');
    }
  }

  Future<void> _toggleDeviceState(String deviceId, String symbolKey, bool newState, String? currentRoomId) async {
    final networkMode = ref.read(networkModeProvider);

    // Optimistically update UI
    setState(() {
      if (currentRoomId != null) {
        _devicesByRoom[currentRoomId]["devices"][deviceId]["state"] = newState;
      } else {
        final deviceIndex = _unassignedDevices.indexWhere((d) => d['id'] == deviceId);
        if (deviceIndex != -1) {
          _unassignedDevices[deviceIndex]['state'] = newState;
        }
      }
    });

    try {
      if (networkMode == NetworkMode.local) {
        print('Using local mode');
        // Use the improved LocalBrokerService method
        await LocalBrokerService().updateSymbolState(symbolKey, newState);
      } else {
        print('Using online mode');
        // Online mode operations
        await _switchService.updateDeviceState(deviceId, newState);
        await _deviceService.updateSymbolSource(symbolKey, AppConstants.deviceSourceMobile);
      }
    } catch (e) {
      print('Error toggling device state: $e');
      // Revert the state on error
      setState(() {
        if (currentRoomId != null) {
          _devicesByRoom[currentRoomId]["devices"][deviceId]["state"] = !newState;
        } else {
          final deviceIndex = _unassignedDevices.indexWhere((d) => d['id'] == deviceId);
          if (deviceIndex != -1) {
            _unassignedDevices[deviceIndex]['state'] = !newState;
          }
        }
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              networkMode == NetworkMode.local
                  ? 'Failed to update device: Check if local broker is running'
                  : 'Failed to update device: Check your internet connection',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _toggleDeviceState(deviceId, symbolKey, newState, currentRoomId),
            ),
          ),
        );
      }
    }
  }

  Widget _buildDeviceCard(String deviceId, Map<String, dynamic> deviceData, String? currentRoomId) {
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
              _getDeviceIcon(symbol),
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
                onChanged: (bool newValue) async {
                  await _toggleDeviceState(deviceId, deviceData["assignedSymbol"], newValue, currentRoomId);
                },
                activeColor: theme.colorScheme.primary,
              ),
              isAdmin
                  ? PopupMenuButton<String?>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String? targetRoomId) {
                  _moveDeviceToRoom(deviceId, deviceData, targetRoomId);
                },
                itemBuilder: (BuildContext context) => [
                  if (currentRoomId != null)
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text(AppConstants.moveToUnassignedLabel),
                    ),
                  ..._roomList
                      .where((roomId) => roomId != currentRoomId)
                      .map((roomId) => PopupMenuItem<String>(
                    value: roomId,
                    child: Text(AppConstants.moveToRoomLabel.replaceAll('{0}', _devicesByRoom[roomId]["name"])),
                  ))
                      .toList(),
                ],
              )
                  : const SizedBox.shrink(),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkMode = ref.watch(networkModeProvider); // Always get latest value

    // final currentEnvId = ref.watch(currentEnvironmentProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final canAdd = roleAsync.asData?.value == 'admin' || roleAsync.asData?.value == 'co-admin';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appBarTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      floatingActionButton: canAdd ? FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        // backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ): null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(AppConstants.loadingMessage, style: theme.textTheme.bodyLarge),
                  ],
                ),
              )
            : _devicesByRoom.isEmpty && _unassignedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(128),),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.noDevicesTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                            canAdd
                                ? AppConstants.addDevicePrompt
                                : AppConstants.contactAdminPrompt,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            )
                        ),
                        const SizedBox(height: 24),
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
                                          AppConstants.unassignedDevicesTitle,
                                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        Text(
                                          AppConstants.deviceCountLabel.replaceAll('{0}', _unassignedDevices.length.toString()),
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
                            final String roomName = roomData["name"] ?? AppConstants.defaultRoomName;
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
                                              AppConstants.deviceCountLabel.replaceAll('{0}', devices.length.toString()),
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


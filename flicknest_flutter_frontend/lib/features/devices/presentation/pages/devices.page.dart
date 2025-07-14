import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../providers/environment/environment_provider.dart';
import '../../../../providers/role/role_provider.dart';
import '../../../../providers/network/network_mode_provider.dart';
import '../../../../constants.dart';
import '../widgets/device_card.dart';
import '../widgets/room_card.dart';
import '../../services/device_operations_service.dart';
import '../dialogs/add_device_dialog.dart';

class DevicesPage extends ConsumerStatefulWidget {
  static const String route = '/devices';
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  late final DeviceOperationsService _deviceOpsService;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _symbolStateSubscription;
  String? _environmentId;

  Map<String, dynamic> _devicesByRoom = {};
  List<Map<String, String>> _availableSymbols = [];
  List<String> _roomList = [];
  bool _loading = true;
  final Map<String, bool> _expandedRooms = {};
  List<Map<String, dynamic>> _unassignedDevices = [];
  bool _isBrokerOnline = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _environmentId = ref.read(currentEnvironmentProvider);
    _deviceOpsService = DeviceOperationsService(_environmentId);
    _setupDevicesListener();
    _setupSymbolStateListener();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _symbolStateSubscription?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  void _setupSymbolStateListener() {
    final networkMode = ref.read(networkModeProvider);
    if (networkMode != NetworkMode.online) return;

    _symbolStateSubscription = _deviceOpsService.listenToSymbolStateChanges(
      (symbolId, newState) async {
        // Update all devices using this symbol
        if (_environmentId == null) return;
        final devicesRef = FirebaseDatabase.instance.ref('environments/$_environmentId/devices');
        final devicesSnapshot = await devicesRef.get();
        if (!devicesSnapshot.exists) return;

        final devices = Map<String, dynamic>.from(devicesSnapshot.value as Map);
        for (final entry in devices.entries) {
          final deviceId = entry.key;
          final device = Map<String, dynamic>.from(entry.value as Map);
          if (device['assignedSymbol'] == symbolId) {
            await devicesRef.child(deviceId).update({'state': newState});
          }
        }
      },
    );
  }

  void _setupDevicesListener() {
    setState(() => _loading = true);

    try {
      if (_environmentId == null) {
        setState(() => _loading = false);
        return;
      }

      final envRef = FirebaseDatabase.instance.ref('environments/$_environmentId');

      // Listen to devices and rooms
      _devicesSubscription = envRef.onValue.listen((event) {
        if (!mounted || _isDisposed) return;

        if (!event.snapshot.exists) {
          setState(() {
            _devicesByRoom = {};
            _unassignedDevices = [];
            _loading = false;
          });
          return;
        }

        final envData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final devices = Map<String, dynamic>.from(envData['devices'] ?? {});
        final rooms = Map<String, dynamic>.from(envData['rooms'] ?? {});

        final Map<String, dynamic> processedDevices = {};
        final List<Map<String, dynamic>> unassignedDevs = [];

        // Process devices and organize by room
        devices.forEach((deviceId, deviceData) {
          final device = Map<String, dynamic>.from(deviceData);
          final roomId = device['roomId'];

          if (roomId == null || roomId == 'unassigned' || !rooms.containsKey(roomId)) {
            unassignedDevs.add({
              'id': deviceId,
              ...device,
            });
          } else {
            if (!processedDevices.containsKey(roomId)) {
              processedDevices[roomId] = {
                'name': rooms[roomId]['name'] ?? 'Unknown Room',
                'devices': {},
              };
            }
            processedDevices[roomId]['devices'][deviceId] = device;
          }
        });

        if (mounted) {
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

      // Fetch available symbols
      _fetchAvailableSymbols();

    } catch (e) {
      print('Error setting up devices listener: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _fetchAvailableSymbols() async {
    try {
      final symbolsRef = FirebaseDatabase.instance.ref('symbols');
      final snapshot = await symbolsRef.get();

      if (!snapshot.exists || !mounted) return;

      final symbolsData = snapshot.value as Map<dynamic, dynamic>;
      final symbolsList = symbolsData.entries.where((entry) => entry.value['available'] == true).map((entry) {
        final symbolData = entry.value as Map<dynamic, dynamic>;
        return {
          'id': entry.key.toString(),
          'name': (symbolData['name'] ?? entry.key).toString(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _availableSymbols = symbolsList.cast<Map<String, String>>();
        });
      }
    } catch (e) {
      print('Error fetching available symbols: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading symbols: $e')),
        );
      }
    }
  }

  Future<void> _handleDeviceStateToggle(
    String deviceId,
    String symbolKey,
    bool newState,
    String? currentRoomId
  ) async {
    final networkMode = ref.read(networkModeProvider);

    // Update UI state immediately
    setState(() {
      if (currentRoomId != null) {
        if (_devicesByRoom[currentRoomId]?["devices"]?[deviceId] != null) {
          _devicesByRoom[currentRoomId]["devices"][deviceId]["state"] = newState;
        }
      } else {
        final deviceIndex = _unassignedDevices.indexWhere((d) => d['id'] == deviceId);
        if (deviceIndex != -1) {
          _unassignedDevices[deviceIndex]['state'] = newState;
        }
      }
    });

    try {
      await _deviceOpsService.updateDeviceState(
        deviceId,
        symbolKey,
        newState,
        networkMode == NetworkMode.local
      );
    } catch (e) {
      if (!mounted) return;

      // Only revert UI state if we're in online mode
      if (networkMode != NetworkMode.local) {
        setState(() {
          if (currentRoomId != null) {
            if (_devicesByRoom[currentRoomId]?["devices"]?[deviceId] != null) {
              _devicesByRoom[currentRoomId]["devices"][deviceId]["state"] = !newState;
            }
          } else {
            final deviceIndex = _unassignedDevices.indexWhere((d) => d['id'] == deviceId);
            if (deviceIndex != -1) {
              _unassignedDevices[deviceIndex]['state'] = !newState;
            }
          }
        });
      }

      final errorMessage = networkMode == NetworkMode.local
          ? 'Note: Local broker not responding, but UI state updated'
          : 'Failed to update device: Check your internet connection';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: networkMode == NetworkMode.local ? Colors.orange : Colors.red,
          action: networkMode == NetworkMode.local ? null : SnackBarAction(
            label: 'Retry',
            onPressed: () {
              if (mounted) {
                _handleDeviceStateToggle(deviceId, symbolKey, newState, currentRoomId);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleDeviceMove(
    String deviceId,
    Map<String, dynamic> deviceData,
    String? targetRoomId
  ) async {
    try {
      await _deviceOpsService.moveDeviceToRoom(deviceId, targetRoomId);
    } catch (e) {
      print('Error moving device: $e');
      // Revert changes on error
      _setupDevicesListener();
    }
  }

  void _handleRoomExpandToggle(String roomId) {
    setState(() {
      _expandedRooms[roomId] = !(_expandedRooms[roomId] ?? true);
    });
  }

  Widget _buildUnassignedDevicesSection(ThemeData theme) {
    return Padding(
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
                    AppConstants.deviceCountLabel.replaceAll(
                      '{0}',
                      _unassignedDevices.length.toString(),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                return DeviceCard(
                  deviceId: device['id'],
                  deviceData: device,
                  currentRoomId: null,
                  roomList: _roomList,
                  devicesByRoom: _devicesByRoom,
                  onToggleDevice: _handleDeviceStateToggle,
                  onMoveDevice: _handleDeviceMove,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkMode = ref.watch(networkModeProvider);
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
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AddDeviceDialog(
            environmentId: _environmentId,
            availableSymbols: _availableSymbols,
            roomList: _roomList,
            devicesByRoom: _devicesByRoom,
          ),
        ),
        child: const Icon(Icons.add),
      ) : null,
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(AppConstants.loadingMessage, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    if (_devicesByRoom.isEmpty && _unassignedDevices.isEmpty) {
      return _buildEmptyState(theme);
    }

    return CustomScrollView(
      slivers: [
        if (_unassignedDevices.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildUnassignedDevicesSection(theme),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final roomEntry = _devicesByRoom.entries.elementAt(index);
              return RoomCard(
                roomId: roomEntry.key,
                roomData: roomEntry.value,
                isExpanded: _expandedRooms[roomEntry.key] ?? true,
                roomList: _roomList,
                devicesByRoom: _devicesByRoom,
                onRoomExpandToggle: _handleRoomExpandToggle,
                onToggleDevice: _handleDeviceStateToggle,
                onMoveDevice: _handleDeviceMove,
              );
            },
            childCount: _devicesByRoom.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    final canAdd = roleAsync.asData?.value == 'admin' || roleAsync.asData?.value == 'co-admin';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 64, color: theme.colorScheme.primary.withAlpha(128)),
          const SizedBox(height: 16),
          Text(
            AppConstants.noDevicesTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            canAdd ? AppConstants.addDevicePrompt : AppConstants.contactAdminPrompt,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

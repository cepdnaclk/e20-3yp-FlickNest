import 'package:flutter/material.dart';
import '../../../../Firebase/switchModel.dart';
import '../../../../Firebase/deviceService.dart';

class RoomsPage extends StatefulWidget {
  static const String route = '/rooms';
  final SwitchService switchService;
  final DeviceService deviceService;

  const RoomsPage({
    super.key,
    required this.switchService,
    required this.deviceService,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  late final SwitchService _switchService;
  late final DeviceService _deviceService;

  Map<String, dynamic> _devicesByRoom = {};
  Map<String, dynamic> _symbolNames = {};
  Map<String, dynamic> _symbolsData = {};
  List<String> _roomList = [];
  List<Map<String, String>> _availableSymbols = [];
  Stream<Map<String, dynamic>>? _symbolsStream;

  @override
  void initState() {
    super.initState();
    _switchService = widget.switchService;
    _deviceService = widget.deviceService;
    _fetchDevices();
    _listenToSymbolChanges();
  }

  @override
  void dispose() {
    _symbolsStream = null; // Clean up stream
    super.dispose();
  }

  // New method to listen to symbol state changes
  void _listenToSymbolChanges() {
    _symbolsStream = _deviceService.getSymbolsStream();
    _symbolsStream?.listen((symbolsData) {
      if (mounted) {
        setState(() {
          _symbolsData = symbolsData;

          // Update device states to match their symbol states
          _devicesByRoom.forEach((roomId, roomData) {
            final devices = roomData["devices"] as Map<String, dynamic>;
            devices.forEach((deviceId, deviceData) {
              final symbolId = deviceData["assignedSymbol"];
              if (symbolId != null && _symbolsData.containsKey(symbolId)) {
                deviceData["state"] = _symbolsData[symbolId]["state"] ?? false;
              }
            });
          });
        });
      }
    });
  }

  void _showAssignToRoomDialog(String deviceId) {
    String? selectedRoom;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Assign Device to Room"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedRoom,
                    hint: Text("Select Room"),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      setState(() {
                        selectedRoom = value;
                      });
                    },
                    items: _roomList.where((roomId) => roomId != "unassigned").map((roomId) {
                      return DropdownMenuItem<String>(
                        value: roomId,
                        child: Text(
                          _devicesByRoom[roomId]["name"],
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Assign"),
                  onPressed: () {
                    if (selectedRoom != null) {
                      _assignDeviceToRoom(deviceId, selectedRoom!);
                      Navigator.pop(context);
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

  void _assignDeviceToRoom(String deviceId, String newRoomId) async {
    print("🟢 Assigning device $deviceId to room $newRoomId");

    // 🔥 Update Firebase
    await _switchService.assignDeviceToRoom(deviceId, newRoomId);

    // 🔄 Update UI immediately
    setState(() {
      final deviceData = _devicesByRoom["unassigned"]["devices"].remove(deviceId);
      if (deviceData != null) {
        if (_devicesByRoom.containsKey(newRoomId)) {
          _devicesByRoom[newRoomId]["devices"][deviceId] = deviceData;
        } else {
          _devicesByRoom[newRoomId] = {
            "name": "New Room",
            "devices": {deviceId: deviceData},
          };
        }
      }
    });
  }

  void _fetchDevices() async {
    print("🟢 Fetching devices and available symbols...");

    final devicesDataStream = _switchService.getDevicesByRoomStream();
    final devicesData = await devicesDataStream.first;
    final availableSymbols = await _deviceService.getAvailableSymbols(); // Fetch available symbols with names

    print("🔵 Fetched Devices Data: $devicesData");
    print("🔵 Available Symbols: $availableSymbols");

    if (devicesData.isEmpty) {
      print("🟠 No devices found.");
    }

    // Fetch symbol names for assigned symbols
    Map<String, String> symbolNames = {};
    for (var roomData in devicesData.values) {
      for (var device in roomData["devices"].values) {
        String symbolId = device["assignedSymbol"] ?? "";
        if (symbolId.isNotEmpty && !symbolNames.containsKey(symbolId)) {
          symbolNames[symbolId] = await _deviceService.getSymbolName(symbolId);
        }
      }
    }

    // Fetch initial symbols data
    final symbolsData = await _deviceService.getSymbolsStream().first;

    if (mounted) {
      setState(() {
        _devicesByRoom = devicesData;
        _symbolNames = symbolNames;
        _symbolsData = symbolsData; // Store initial symbols data
        _roomList = devicesData.keys.toList();
        _availableSymbols = availableSymbols; // Update available symbols with names

        // Ensure device states match symbol states
        _devicesByRoom.forEach((roomId, roomData) {
          final devices = roomData["devices"] as Map<String, dynamic>;
          devices.forEach((deviceId, deviceData) {
            final symbolId = deviceData["assignedSymbol"];
            if (symbolId != null && _symbolsData.containsKey(symbolId)) {
              deviceData["state"] = _symbolsData[symbolId]["state"] ?? false;
            }
          });
        });
      });
    }
  }

  /// 🔥 Toggle device state (On/Off)
  void _toggleDeviceState(String deviceId, bool currentState, String assignedSymbol) async {
    bool newState = !currentState;
    print("🟢 Toggling device: $deviceId to ${newState ? "ON" : "OFF"}");

    // 🔥 Update Firebase for both device and symbol state
    await _switchService.updateDeviceState(deviceId, newState);
    await _deviceService.updateSymbolState(assignedSymbol, newState);

    // 🔄 Update UI immediately
    setState(() {
      _devicesByRoom.forEach((roomId, roomData) {
        if (roomData["devices"].containsKey(deviceId)) {
          _devicesByRoom[roomId]["devices"][deviceId]["state"] = newState;
        }
      });
    });
  }

  /// 🔥 Remove device from a room (Moves to Unassigned)
  void _removeDeviceFromRoom(String roomId, String deviceId) async {
    print("🟢 Removing device $deviceId from room $roomId");

    // 🔥 Update Firebase
    await _switchService.removeDeviceFromRoom(deviceId);

    // 🔄 Update UI immediately
    setState(() {
      final deviceData = _devicesByRoom[roomId]["devices"].remove(deviceId);
      if (deviceData != null) {
        _devicesByRoom["unassigned"]["devices"][deviceId] = deviceData;
      }
    });
  }

  void _showAddDeviceDialog() {
    String deviceName = "";
    String? selectedSymbolId; // Store symbol ID
    String? selectedRoom;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Add New Device"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: "Device Name"),
                    onChanged: (value) {
                      deviceName = value;
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedSymbolId,
                    hint: Text("Select Symbol"),
                    dropdownColor: Colors.white,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSymbolId = newValue; // Store symbol ID
                      });
                    },
                    items: _availableSymbols.map<DropdownMenuItem<String>>((Map<String, String> symbol) {
                      return DropdownMenuItem<String>(
                        value: symbol["id"], // Store symbol ID
                        child: Text(symbol["name"]!), // Display symbol name
                      );
                    }).toList(),
                  ),
                  DropdownButton<String>(
                    value: selectedRoom,
                    hint: Text("Select Room (Optional)"),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      setState(() {
                        selectedRoom = value;
                      });
                    },
                    items: _roomList.map((roomId) {
                      return DropdownMenuItem<String>(
                        value: roomId,
                        child: Text(
                          _devicesByRoom[roomId]["name"],
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Add Device"),
                  onPressed: () {
                    if (deviceName.isNotEmpty && selectedSymbolId != null) {
                      _deviceService.addDevice(deviceName, selectedSymbolId!, selectedRoom);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Devices"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddDeviceDialog,
          )
        ],
      ),
      body: _devicesByRoom.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: _devicesByRoom.entries.map((roomEntry) {
          final String roomId = roomEntry.key;
          final Map<String, dynamic> roomData = roomEntry.value;
          final String roomName = roomData["name"];
          final Map<String, dynamic> devices = roomData["devices"];

          return ExpansionTile(
            title: Text(roomName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            children: devices.entries.map((deviceEntry) {
              final String deviceId = deviceEntry.key;
              final Map<String, dynamic> deviceData = deviceEntry.value;
              final bool deviceState = deviceData["state"] ?? false;
              final String assignedSymbolId = deviceData["assignedSymbol"] ?? "N/A";
              final String symbolName = _symbolNames[assignedSymbolId] ?? "Unknown Symbol";

              return ListTile(
                title: Text(deviceData["name"] ?? "Unknown Device"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Symbol: $symbolName"),
                    Text("State: ${deviceState ? "ON" : "OFF"}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: deviceState,
                      onChanged: (bool newValue) {
                        _toggleDeviceState(deviceId, deviceState, assignedSymbolId);
                      },
                    ),
                    if (roomId == "unassigned") // Show "Assign to Room" button only for unassigned devices
                      IconButton(
                        icon: Icon(Icons.assignment, color: Colors.blue),
                        onPressed: () {
                          _showAssignToRoomDialog(deviceId);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        _removeDeviceFromRoom(roomId, deviceId);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
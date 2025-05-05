import 'package:flutter/material.dart';
import '../../../../Firebase/switchModel.dart';
import '../../../../Firebase/deviceService.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _fetchAvailableSymbols();
  }

  /// 🔥 Fetch devices
  void _fetchDevices() async {
    print("🟢 Fetching devices from Firebase...");
    final devicesDataStream = _switchService.getDevicesByRoomStream();
    final devicesData = await devicesDataStream.first;

    print("🔵 Fetched Devices by Room: $devicesData");

    if (devicesData.isEmpty) {
      print("🟠 No devices received from Firebase");
    }

    if (mounted) {
      setState(() {
        _devicesByRoom = devicesData;
        _roomList = devicesData.keys.toList();
      });
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

  /// 🔥 Show Add Device Dialog
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
                    value: selectedSymbol,
                    hint: Text("Select Symbol"),
                    dropdownColor: Colors.white,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSymbol = newValue;
                      });
                    },
                    items: _availableSymbols.map<DropdownMenuItem<String>>((String symbol) {
                      return DropdownMenuItem<String>(
                        value: symbol,
                        child: Text(symbol),
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

              return ListTile(
                title: Text(deviceData["name"] ?? "Unknown Device"),
                subtitle: Text("Symbol: ${deviceData["symbol"] ?? "N/A"}"),
                trailing: Switch(
                  value: deviceState,
                  onChanged: (bool newValue) {
                    _switchService.updateDeviceState(deviceId, newValue);
                    setState(() {
                      _devicesByRoom[roomId]["devices"][deviceId]["state"] = newValue;
                    });
                  },
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
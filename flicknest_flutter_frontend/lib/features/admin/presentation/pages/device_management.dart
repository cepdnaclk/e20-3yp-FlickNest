import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/Firebase/deviceService.dart';

final deviceServiceProvider = Provider((ref) => DeviceService());

class DeviceManagementPage extends ConsumerStatefulWidget {
  static const String route = '/admin/devices';
  
  const DeviceManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends ConsumerState<DeviceManagementPage> {
  late Future<List<Map<String, String>>> _availableSymbols;
  late Future<List<String>> _usedSymbols;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final deviceService = ref.read(deviceServiceProvider);
    _availableSymbols = deviceService.getAvailableSymbols();
    _usedSymbols = deviceService.getUsedSymbols();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _refreshData();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceStats(),
            const SizedBox(height: 24),
            _buildDeviceList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceStats() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_availableSymbols, _usedSymbols]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final availableCount = snapshot.data?[0].length ?? 0;
        final usedCount = snapshot.data?[1].length ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Devices', (availableCount + usedCount).toString()),
                _buildStatItem('Active Devices', usedCount.toString()),
                _buildStatItem('Available Symbols', availableCount.toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: FutureBuilder<List<String>>(
        future: _usedSymbols,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final usedSymbols = snapshot.data ?? [];

          if (usedSymbols.isEmpty) {
            return const Center(
              child: Text('No devices found. Add a device to get started.'),
            );
          }

          return ListView.builder(
            itemCount: usedSymbols.length,
            itemBuilder: (context, index) {
              final symbolId = usedSymbols[index];
              return FutureBuilder<String>(
                future: ref.read(deviceServiceProvider).getSymbolName(symbolId),
                builder: (context, snapshot) {
                  final symbolName = snapshot.data ?? 'Loading...';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.device_hub),
                      title: Text(symbolName),
                      subtitle: Text('Symbol ID: $symbolId'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteDeviceDialog(context, symbolId),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDeviceDialog(BuildContext context) async {
    final deviceNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedSymbol;

    final availableSymbols = await ref.read(deviceServiceProvider).getAvailableSymbols();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Device'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: deviceNameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Symbol'),
                value: selectedSymbol,
                items: availableSymbols.map((symbol) {
                  return DropdownMenuItem(
                    value: symbol['id'],
                    child: Text(symbol['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedSymbol = value;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a symbol';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(deviceServiceProvider).addDevice(
                      deviceNameController.text,
                      selectedSymbol!,
                      null, // Room ID can be added later
                    );
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _refreshData();
                });
              }
            },
            child: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDeviceDialog(BuildContext context, String symbolId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // We need to generate a device ID based on the symbol ID
              final deviceId = 'dev_${symbolId.replaceAll('sym_', '')}';
              await ref.read(deviceServiceProvider).removeDevice(deviceId, symbolId);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {
                _refreshData();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 
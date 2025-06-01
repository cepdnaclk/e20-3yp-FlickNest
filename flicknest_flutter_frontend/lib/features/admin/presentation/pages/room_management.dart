import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

class RoomManagementPage extends ConsumerStatefulWidget {
  static const String route = '/admin/rooms';
  
  const RoomManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends ConsumerState<RoomManagementPage> {
  final DatabaseReference _roomsRef = FirebaseDatabase.instance.ref('environments/env_12345/rooms');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _roomsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No rooms found. Add a room to get started.'),
            );
          }

          final roomsData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomStats(roomsData),
                const SizedBox(height: 24),
                const Text(
                  'Rooms',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildRoomList(roomsData),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomStats(Map<String, dynamic> roomsData) {
    int totalRooms = roomsData.length;
    int totalDevices = 0;
    roomsData.forEach((_, room) {
      if (room is Map && room.containsKey('devices')) {
        totalDevices += (room['devices'] as Map).length;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Rooms', totalRooms.toString()),
            _buildStatItem('Total Devices', totalDevices.toString()),
          ],
        ),
      ),
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

  Widget _buildRoomList(Map<String, dynamic> roomsData) {
    return ListView.builder(
      itemCount: roomsData.length,
      itemBuilder: (context, index) {
        final roomId = roomsData.keys.elementAt(index);
        final room = roomsData[roomId] as Map<dynamic, dynamic>;
        final deviceCount = room['devices'] != null ? (room['devices'] as Map).length : 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.meeting_room),
            title: Text(room['name'] ?? 'Unnamed Room'),
            subtitle: Text('$deviceCount devices'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditRoomDialog(context, roomId, room),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteRoomDialog(context, roomId),
                ),
              ],
            ),
            onTap: () => _showRoomDetailsDialog(context, roomId, room),
          ),
        );
      },
    );
  }

  Future<void> _showAddRoomDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Room Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a room name';
              }
              return null;
            },
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
                final newRoomRef = _roomsRef.push();
                await newRoomRef.set({
                  'name': nameController.text,
                  'devices': {},
                });
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Add Room'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRoomDialog(
    BuildContext context,
    String roomId,
    Map<dynamic, dynamic> room,
  ) async {
    final nameController = TextEditingController(text: room['name'] as String?);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Room Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a room name';
              }
              return null;
            },
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
                await _roomsRef.child(roomId).update({
                  'name': nameController.text,
                });
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteRoomDialog(BuildContext context, String roomId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text(
          'Are you sure you want to delete this room? This will also remove all device associations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _roomsRef.child(roomId).remove();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoomDetailsDialog(
    BuildContext context,
    String roomId,
    Map<dynamic, dynamic> room,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room['name'] as String? ?? 'Room Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room ID: $roomId'),
              const SizedBox(height: 16),
              const Text(
                'Devices:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (room['devices'] != null && (room['devices'] as Map).isNotEmpty)
                ...((room['devices'] as Map).keys).map(
                  (deviceId) => ListTile(
                    leading: const Icon(Icons.device_hub),
                    title: Text(deviceId as String),
                  ),
                )
              else
                const Text('No devices in this room'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 
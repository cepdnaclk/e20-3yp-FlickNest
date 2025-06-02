import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/environment_provider.dart';
import 'room_details.page.dart';

class RoomsPage extends ConsumerStatefulWidget {
  static const String route = '/rooms';

  const RoomsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  Map<String, dynamic> rooms = {};
  bool isLoading = true;
  String? environmentName;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    print('🔵 RoomsPage initialized');
    print('🔵 Current User: ${currentUser?.email} (${currentUser?.uid})');
  }

  @override
  Widget build(BuildContext context) {
    final currentEnvId = ref.watch(currentEnvironmentProvider);
    print('🔵 Current Environment ID: $currentEnvId');

    if (currentEnvId == null) {
      return const Scaffold(
        body: Center(
          child: Text('No environment selected'),
        ),
      );
    }

    final envDetailsAsync = ref.watch(environmentDetailsProvider(currentEnvId));

    return Scaffold(
      appBar: AppBar(
        title: envDetailsAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Rooms'),
          data: (envData) => Text(envData?['name'] ?? 'Rooms'),
        ),
      ),
      body: envDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (envData) {
          if (envData == null) {
            return const Center(
              child: Text('Environment not found'),
            );
          }

          final rooms = envData['rooms'] as Map<String, dynamic>? ?? {};

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.room_preferences,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Rooms',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a room to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddRoomDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Room'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomId = rooms.keys.elementAt(index);
              final room = rooms[roomId];
              final deviceCount = (room['devices'] as Map?)?.length ?? 0;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(26),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    print('👆 Tapped room: ${room['name']} ($roomId)');
                    context.push(
                      RoomDetailsPage.route,
                      extra: {
                        'environmentId': currentEnvId,
                        'roomId': roomId,
                        'roomName': room['name'],
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.room_preferences,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room['name'] ?? 'Unnamed Room',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$deviceCount ${deviceCount == 1 ? 'device' : 'devices'}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRoomDialog() {
    final nameController = TextEditingController();
    final currentEnvId = ref.read(currentEnvironmentProvider);
    
    if (currentEnvId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No environment selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Room Name',
            hintText: 'Enter room name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              try {
                print('➕ Adding new room: $name');
                print('➕ Environment ID: $currentEnvId');
                
                // Create new room with unique ID
                final newRoomRef = FirebaseDatabase.instance
                    .ref('environments/$currentEnvId/rooms')
                    .push();

                print('➕ New room ID: ${newRoomRef.key}');
                await newRoomRef.set({
                  'name': name,
                  'devices': {},
                });
                print('✅ Room created successfully');

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error creating room: $e');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating room: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
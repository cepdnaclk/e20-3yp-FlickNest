import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import '../constants.dart';

class LocalWebSocketService {
  static final LocalWebSocketService _instance = LocalWebSocketService._internal();
  factory LocalWebSocketService() => _instance;
  LocalWebSocketService._internal();

  late IO.Socket socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect() {
    final url = AppConstants.isEmulator
        ? AppConstants.localBrokerUrl.replaceAll('http://', 'ws://')
        : AppConstants.localWebSocketUrl;

    print('Connecting to WebSocket at: $url');

    socket = IO.io(
      url,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(5000)
        .setQuery({'protocol': 'socket.io'})
        .build()
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket.onConnect((_) {
      print('WebSocket Connected successfully');
      _connected = true;
    });

    socket.onDisconnect((_) {
      print('WebSocket Disconnected');
      _connected = false;
    });

    socket.onConnectError((error) {
      print('WebSocket Connection Error: $error');
      _connected = false;
    });

    socket.onError((error) {
      print('WebSocket Error: $error');
      _connected = false;
    });

    // Clear any existing listeners before connecting
    socket.clearListeners();
    socket.connect();
  }

  void disconnect() {
    print('Disconnecting WebSocket');
    socket.disconnect();
    socket.dispose();
    _connected = false;
  }

  void requestAll(String entity, Function(dynamic) onData) {
    if (!_connected) {
      print('WebSocket not connected, attempting to connect...');
      connect();
      return;
    }

    socket.emit('request_all_$entity');
    socket.on('all_$entity', (data) {
      onData(data);
    });
  }

  void updateEntity(String entity, String id, Map<String, dynamic> data) {
    if (!_connected) {
      print('WebSocket not connected, cannot update entity');
      return;
    }

    final payload = jsonEncode({
      'id': id,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('Emitting update via WebSocket: $payload');
    socket.emit('update_$entity', payload);
  }

  void listenUpdates(Function(dynamic) onUpdate) {
    socket.on('update', (data) {
      onUpdate(data);
    });
  }
}


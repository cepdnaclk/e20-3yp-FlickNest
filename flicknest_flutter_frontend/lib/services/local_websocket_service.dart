import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

class LocalWebSocketService {
  static final LocalWebSocketService _instance = LocalWebSocketService._internal();
  factory LocalWebSocketService() => _instance;
  LocalWebSocketService._internal();

  late IO.Socket socket;
  bool _connected = false;

  void connect(String url) {
    socket = IO.io(url,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );
    socket.onConnect((_) {
      _connected = true;
    });
    socket.onDisconnect((_) {
      _connected = false;
    });
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void requestAll(String entity, Function(dynamic) onData) {
    socket.emit('request_all_$entity');
    socket.on('all_$entity', (data) {
      onData(data);
    });
  }

  void updateEntity(String entity, String id, Map<String, dynamic> data) {
    socket.emit('update_$entity', jsonEncode({'id': id, 'data': data}));
  }

  void listenUpdates(Function(dynamic) onUpdate) {
    socket.on('update', (data) {
      onUpdate(data);
    });
  }
}


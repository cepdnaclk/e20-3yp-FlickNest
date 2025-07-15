import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../helpers/local_broker_config.dart';

class LocalWebSocketService {
  static final LocalWebSocketService _instance = LocalWebSocketService._internal();
  IO.Socket? _socket;
  bool _isConnected = false;
  Function(dynamic)? _updateCallback;

  factory LocalWebSocketService() {
    return _instance;
  }

  LocalWebSocketService._internal();

  bool get isConnected => _isConnected;

  Future connect() async {
    if (_isConnected) return;

    try {
      final brokerUrl = await LocalBrokerConfig.getBrokerUrl();
      print('🔵 Connecting to Socket.IO server at: $brokerUrl');

      _socket = IO.io(brokerUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .build()
      );

      _socket?.onConnect((_) {
        print('🔵 Connected to Socket.IO server');
        _isConnected = true;
      });

      _socket?.on('update', (data) {
        print('📩 Socket.IO update received: $data');
        try {
          if (data is Map) {
            String symbolId = data.keys.first.toString();
            var symbolDataRaw = data[symbolId];
            Map<String, dynamic> symbolData = {};
            if (symbolDataRaw is Map) {
              symbolDataRaw.forEach((k, v) {
                symbolData[k.toString()] = v;
              });
            }
            dynamic stateRaw = symbolData['state'];
            bool state;
            if (stateRaw is String) {
              state = stateRaw.toLowerCase() == 'on' || stateRaw.toLowerCase() == 'true';
              print('stateRaw is String');
            } else if (stateRaw is bool) {
              state = stateRaw;
            } else {
              state = false;
            }
            print('📱 Processing symbol: $symbolId, new state: $state');
            if (_updateCallback != null) {
              _updateCallback!(data);
            }
          } else {
            print('⚠️ Unexpected data format: $data');
          }
        } catch (e) {
          print('🔴 Error processing Socket.IO update: $e');
        }
      });

      _socket?.onDisconnect((_) {
        print('🔴 Disconnected from Socket.IO server');
        _isConnected = false;
        // Try to reconnect
        Future.delayed(const Duration(seconds: 5), () {
          if (!_isConnected) {
            print('🔄 Attempting to reconnect...');
            connect();
          }
        });
      });

      _socket?.connect();

    } catch (e) {
      print('🔴 Socket.IO connection failed: $e');
      _isConnected = false;
      // Try to reconnect after failure
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          print('🔄 Attempting to reconnect...');
          connect();
        }
      });
    }
  }

  void updateEntity(String entity, String id, dynamic data) {
    if (!_isConnected) {
      print('⚠️ Socket not connected');
      return;
    }

    final message = {
      'type': 'update',
      'entity': entity,
      'id': id,
      'data': data,
    };

    print('📤 Emitting update: $message');
    _socket?.emit('update', message);
  }

  void listenUpdates(Function(dynamic) callback) {
    _updateCallback = callback;
  }

  void requestAll(String entity, Function(dynamic) callback) {
    if (!_isConnected) {
      print('⚠️ Socket not connected');
      return;
    }

    _updateCallback = callback;

    final request = {
      'entity': entity,
      'action': 'getAll'
    };

    print('📤 Requesting all $entity');
    _socket?.emit('request', request);
  }

  Future disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
    _updateCallback = null;
    print('🔵 Socket.IO disconnected');
  }
}



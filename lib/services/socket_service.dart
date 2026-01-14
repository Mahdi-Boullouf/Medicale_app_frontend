import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../utils/api_config.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnecting = false;

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  IO.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;
  String? get currentUserId => _currentUserId;

  Future<bool> connect(String userId) async {
    // If already connecting, wait
    if (_isConnecting) {
      print('⏳ Socket connection in progress, waiting...');
      int attempts = 0;
      while (_isConnecting && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
    }

    // If already connected with same user
    if (_socket != null && _socket!.connected && _currentUserId == userId) {
      print('✅ Socket already connected');
      return true;
    }

    // If connected with different user, disconnect first
    if (_socket != null && _socket!.connected && _currentUserId != userId) {
      print('⚠️ Disconnecting previous socket connection');
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;
    final completer = Completer<bool>();
    final String serverUrl = ApiConfig.baseUrl;

    print('');
    print('╔══════════════════════════════════════════╗');
    print('║        🔌 CONNECTING SOCKET              ║');
    print('╚══════════════════════════════════════════╝');
    print('   • User ID : $userId');
    print('   • Server  : $serverUrl');
    print('');

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setTimeout(20000)
          .setExtraHeaders({'userId': userId})
          .build(),
    );

    _setupListeners(userId, completer);
    _socket!.connect();

    return await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        print('⏱️ Socket connection timeout');
        _isConnecting = false;
        return false;
      },
    );
  }

  void _setupListeners(String userId, Completer<bool> completer) {
    _socket!.onConnect((_) {
      print('');
      print('✅ SOCKET CONNECTED');
      print('   • Socket ID: ${_socket!.id}');
      print('   • User ID  : $userId');

      _socket!.emit('joinChatRoom', userId);
      print('📡 Emitted: joinChatRoom with userId: $userId');

      Future.delayed(const Duration(milliseconds: 800), () {
        print('✅ Socket ready');
        if (!completer.isCompleted) {
          completer.complete(true);
          _isConnecting = false;
        }
      });
    });

    _socket!.onDisconnect((reason) {
      print('❌ Socket disconnected: $reason');
      _isConnecting = false;
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connect error: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
        _isConnecting = false;
      }
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
    });

    _socket!.onReconnect((attempt) {
      print('🔄 Socket reconnected (attempt $attempt)');
      if (_currentUserId != null) {
        _socket!.emit('joinChatRoom', _currentUserId);
        print('📡 Re-joined room after reconnect');
      }
    });

    _socket!.on('socket:connected', (data) {
      print('✅ Backend confirmed connection: $data');
    });
  }

  Future<bool> emit(String event, dynamic data) async {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Socket not connected, attempting reconnect...');
      if (_currentUserId != null) {
        final ok = await connect(_currentUserId!);
        if (!ok) {
          print('❌ Reconnection failed');
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        print('❌ No user ID for reconnection');
        return false;
      }
    }

    print('');
    print('📤 Emitting event: $event');
    print('   Data: $data');
    print('   Socket ID: ${_socket!.id}');
    print('');

    try {
      _socket!.emit(event, data);
      print('✅ Event emitted successfully');
      return true;
    } catch (e) {
      print('❌ Error emitting event: $e');
      return false;
    }
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
      print('👂 Listening to: $event');
    }
  }

  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
      print('🔇 Stopped listening to: $event');
    }
  }

  void disconnect() {
    if (_socket != null) {
      print('🔌 Disconnecting socket');

      if (_currentUserId != null && _socket!.connected) {
        _socket!.emit('user:offline', {'userId': _currentUserId});
      }

      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();

      _socket = null;
      _currentUserId = null;
      _isConnecting = false;

      print('✅ Socket disconnected and disposed');
    }
  }

  Future<bool> ensureConnected() async {
    if (_socket == null || !_socket!.connected) {
      if (_currentUserId != null) {
        return await connect(_currentUserId!);
      }
      return false;
    }
    return true;
  }
}
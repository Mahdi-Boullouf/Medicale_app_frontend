import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../utils/api_config.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnecting = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<void> _reconnectController =
      StreamController<void>.broadcast();

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  IO.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<void> get reconnectStream => _reconnectController.stream;
  String? get currentUserId => _currentUserId;

  Future<bool> connect(String userId) async {
    // If already connecting, wait
    if (_isConnecting) {
      debugPrint('⏳ Socket connection in progress, waiting...');
      int attempts = 0;
      while (_isConnecting && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
    }

    // If already connected with same user
    if (_socket != null && _socket!.connected && _currentUserId == userId) {
      debugPrint('✅ Socket already connected');
      // Re-emit join room just in case
      _socket!.emit('joinUserRoom', userId);
      return true;
    }

    // If connected with different user, disconnect first
    if (_socket != null && _socket!.connected && _currentUserId != userId) {
      debugPrint('⚠️ Disconnecting previous socket connection');
      disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;
    final completer = Completer<bool>();
    final String serverUrl = ApiConfig.baseUrl;

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║        🔌 CONNECTING SOCKET              ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('   • User ID : $userId');
    debugPrint('   • Server  : $serverUrl');
    debugPrint('');

    // Cleanup any existing socket instance if it was disconnected
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(5000) // Increased to 5s to reduce polling spam
          .setReconnectionDelayMax(10000)
          .setTimeout(20000)
          .setExtraHeaders({'userId': userId})
          .build(),
    );

    _setupListeners(userId, completer);
    _socket!.connect();

    return await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('⏱️ Socket connection timeout');
        _isConnecting = false;
        return false;
      },
    );
  }

  void _setupListeners(String userId, Completer<bool> completer) {
    _socket!.onConnect((_) {
      debugPrint('');
      debugPrint('✅ SOCKET CONNECTED');
      debugPrint('   • Socket ID: ${_socket!.id}');
      debugPrint('   • User ID  : $userId');

      _socket!.emit('joinUserRoom', userId);
      debugPrint('📡 Emitted: joinUserRoom with userId: $userId');

      Future.delayed(const Duration(milliseconds: 800), () {
        debugPrint('✅ Socket ready');
        _connectionController.add(true);
        if (!completer.isCompleted) {
          completer.complete(true);
          _isConnecting = false;
        }
      });
    });

    _socket!.onDisconnect((reason) {
      debugPrint('❌ Socket disconnected: $reason');
      _isConnecting = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connect error: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
        _isConnecting = false;
      }
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
    });

    _socket!.onReconnect((attempt) {
      debugPrint('🔄 Socket reconnected (attempt $attempt)');
      if (_currentUserId != null) {
        _socket!.emit('joinUserRoom', _currentUserId);
        debugPrint('📡 Re-joined room after reconnect');
        _reconnectController.add(null);
      }
    });

    _socket!.on('socket:connected', (data) {
      debugPrint('✅ Backend confirmed connection: $data');
    });
  }

  Future<bool> emit(String event, dynamic data) async {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, attempting reconnect...');
      if (_currentUserId != null) {
        final ok = await connect(_currentUserId!);
        if (!ok) {
          debugPrint('❌ Reconnection failed');
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        debugPrint('❌ No user ID for reconnection');
        return false;
      }
    }

    debugPrint('');
    debugPrint('📤 Emitting event: $event');
    debugPrint('   Data: $data');
    debugPrint('   Socket ID: ${_socket!.id}');
    debugPrint('');

    try {
      _socket!.emit(event, data);
      debugPrint('✅ Event emitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error emitting event: $e');
      return false;
    }
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
      debugPrint('👂 Listening to: $event');
    }
  }

  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
      debugPrint('🔇 Stopped listening to: $event');
    }
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 Disconnecting socket');

      if (_currentUserId != null && _socket!.connected) {
        _socket!.emit('user:offline', {'userId': _currentUserId});
      }

      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();

      _socket = null;
      _currentUserId = null;
      _isConnecting = false;

      debugPrint('✅ Socket disconnected and disposed');
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

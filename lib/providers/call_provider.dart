import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/agora_service.dart';
import '../services/agora_chat_service.dart';
import '../services/active_call_state.dart';
import '../services/callkit_service.dart';

class CallProvider extends ChangeNotifier {
  final AgoraService _agoraService = AgoraService.instance;

  // State variables
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isCallConnected = false;
  bool _isInitializing = true;
  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;
  bool _channelJoined = false;

  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _callDuration = '00:00';
  Timer? _unansweredTimer;

  // Call metadata
  late String chatId;
  late String userName;
  String? userAvatar;
  late String otherUserId;
  late bool isInitiator;
  String? uuid;
  late bool isVideoCall;
  late BuildContext _context;

  // Getters
  int? get remoteUid => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCallConnected => _isCallConnected;
  bool get isInitializing => _isInitializing;
  String get callStatus => _callStatus;
  String get callDuration => _callDuration;
  AgoraService get agoraService => _agoraService;

  bool canPop = false; // Controls PopScope

  void initCall({
    required BuildContext context,
    required String chatId,
    required String userName,
    String? userAvatar,
    required String otherUserId,
    required bool isInitiator,
    String? uuid,
    required bool isVideoCall,
  }) {
    _context = context;
    this.chatId = chatId;
    this.userName = userName;
    this.userAvatar = userAvatar;
    this.otherUserId = otherUserId;
    this.isInitiator = isInitiator;
    this.uuid = uuid;
    this.isVideoCall = isVideoCall;

    WakelockPlus.enable();
    _loadCurrentUserIdAndInitialize();
  }

  Future<void> _loadCurrentUserIdAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await _initializeCall();
      } else {
        final profileResult = await ApiService.getUserProfile();
        if (profileResult['success'] == true) {
          _currentUserId = profileResult['data']['_id']?.toString();
          if (_currentUserId != null) {
            await prefs.setString('user_id', _currentUserId!);
          }
          await _initializeCall();
        } else {
          throw Exception('Failed to load user profile');
        }
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
      _showError('Failed to initialize: $e');
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;

    try {
      _callStatus = 'Setting up ${isVideoCall ? "video" : "audio"}...';
      notifyListeners();

      await ActiveCallState.saveActiveCall(
        chatId: chatId,
        userName: userName,
        userAvatar: userAvatar,
        otherUserId: otherUserId,
        isInitiator: isInitiator,
        callType: isVideoCall ? 'video' : 'audio',
      );

      await _agoraService.initialize(skipPermissions: !isVideoCall);

      // Map Agora events
      _agoraService.onUserJoined = (uid, elapsed) {
        if (_isDisposed) return;
        _remoteUid = uid;
        _isCallConnected = true;
        _callStatus = 'Connected';
        notifyListeners();
        _startCallTimer();
      };

      _agoraService.onUserOffline = (uid, reason) {
        if (_isDisposed) return;
        _remoteUid = null;
        _callStatus = 'User Offline';
        notifyListeners();
        // Disconnect immediately on user offline
        endCall();
      };

      _agoraService.onConnectionStateChanged = (state, reason) {
        if (_isDisposed) return;
        if (state == ConnectionStateType.connectionStateReconnecting) {
          _callStatus = 'Reconnecting...';
        } else if (state == ConnectionStateType.connectionStateFailed) {
          _callStatus = 'Connection Failed';
          _showError('Connection failed: $reason');
          endCall();
        } else if (state == ConnectionStateType.connectionStateConnected) {
          _callStatus = _isCallConnected
              ? (_callDuration.isEmpty ? 'Connected' : _callDuration)
              : 'Connected';
        }
        notifyListeners();
      };

      // Recover remote users for background cases
      if (_agoraService.remoteUids.isNotEmpty) {
        _remoteUid = _agoraService.remoteUids.first;
        _isCallConnected = true;
        _callStatus = 'Connected';
        _startCallTimer();
      }

      // Socket setup
      if (_currentUserId != null) {
        if (!SocketService.instance.isConnected) {
          await SocketService.instance.connect(_currentUserId!);
        } else {
          SocketService.instance.socket?.emit('joinUserRoom', _currentUserId!);
        }
      }

      _setupSocketListeners();

      _isInitializing = false;
      notifyListeners();

      if (isInitiator) {
        _callStatus = 'Calling...';
        notifyListeners();
        _unansweredTimer = Timer(const Duration(seconds: 30), () {
          if (!_isCallConnected) {
            _showError('No answer');
            endCall();
          }
        });
      } else {
        await _joinAgoraChannel();
      }
    } catch (e) {
      debugPrint('Error initializing call: $e');
      _showError('Failed to start call: $e');
    }
  }

  Future<void> _joinAgoraChannel() async {
    if (_channelJoined) return;
    _channelJoined = true;

    try {
      _callStatus = 'Securing connection...';
      notifyListeners();

      String? token = CallKitService.consumeCachedAgoraToken();

      if (token == null) {
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            final result = await ApiService.getAgoraToken(
              channelName: chatId,
            ).timeout(const Duration(seconds: 8));
            if (result['success'] == true) {
              token = result['data']['token'];
              break;
            }
          } catch (e) {
            if (attempt == 0)
              await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (token == null) {
        _showError('Connection security failed');
        return;
      }

      // Upgrade background audio to video if foregrounded
      if (_agoraService.currentChannel == chatId) {
        if (isVideoCall) {
          await _agoraService.engine?.enableVideo();
          await _agoraService.engine?.startPreview();
        }
        if (_agoraService.remoteUids.isNotEmpty) {
          _remoteUid = _agoraService.remoteUids.first;
          _isCallConnected = true;
        }
        _callStatus = 'Connected';
        notifyListeners();
        if (_isCallConnected) _startCallTimer();
        return;
      }

      if (_currentUserId != null) {
        await _agoraService.joinChannelWithUserAccount(
          channelName: chatId,
          userAccount: _currentUserId!,
          isVideo: isVideoCall,
          token: token,
        );
      } else {
        await _agoraService.joinChannel(
          channelName: chatId,
          uid: 0,
          isVideo: isVideoCall,
          token: token,
        );
      }

      if (!isSpeakerOn && !isVideoCall) {
        // Explicitly set speakerphone off for audio calls if it was not enabled
        await _agoraService.setSpeakerphone(false);
      }

      _callStatus = 'Connected';
      _isCallConnected = true;
      notifyListeners();
      _startCallTimer();
    } catch (e) {
      _showError('Failed to connect to call');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    socket.off('call:accepted');
    socket.off('call:accept');
    socket.off('call:ended');
    socket.off('call:rejected');

    void handleCallAccepted(dynamic data) async {
      if (data['chatId'] == chatId && !_channelJoined) {
        _unansweredTimer?.cancel();
        _unansweredTimer = null;
        _callStatus = 'Connecting...';
        notifyListeners();
        await _joinAgoraChannel();
      }
    }

    socket.on('call:accepted', handleCallAccepted);
    socket.on('call:accept', handleCallAccepted);

    socket.on('call:ended', (data) {
      if (data['chatId'] == chatId) endCall();
    });

    socket.on('call:rejected', (data) {
      if (data['chatId'] == chatId) {
        _showError('Call declined');
        Future.delayed(const Duration(seconds: 1), endCall);
      }
    });
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
      _callDuration = isVideoCall
          ? '$minutes:$seconds'
          : _formatDuration(_callDurationSeconds);
      notifyListeners();
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _agoraService.toggleAudio(_isMuted);
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    _agoraService.toggleVideo(_isVideoOff);
    notifyListeners();
  }

  void switchCamera() {
    _agoraService.switchCamera();
  }

  void toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _agoraService.setSpeakerphone(_isSpeakerOn);
    notifyListeners();
  }

  void endCall() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _callTimer?.cancel();
    _unansweredTimer?.cancel();

    await ActiveCallState.clearActiveCall();

    try {
      if (otherUserId.isNotEmpty && isInitiator) {
        String status = _isCallConnected ? 'ended' : 'cancelled';
        await AgoraChatService.instance.sendCallLog(
          conversationId: otherUserId,
          callType: isVideoCall ? 'video' : 'audio',
          status: status,
          duration: _isCallConnected ? _callDuration : '',
          backendChatId: chatId,
          uuid: uuid,
        );
      }
    } catch (e) {
      debugPrint('Failed to send call log: $e');
    }

    await FlutterCallkitIncoming.endAllCalls();

    try {
      await ApiService.endCall(
        chatId: chatId,
        toUserId: otherUserId,
        uuid: uuid,
      );
    } catch (e) {
      debugPrint('API endCall error, falling back to socket: $e');
    }

    // Always notify socket to be safe
    SocketService.instance.emit('call:end', {
      'chatId': chatId,
      'toUserId': otherUserId,
      'fromUserId': _currentUserId,
      'uuid': uuid,
    });

    await _agoraService.leaveChannel();
    _agoraService.onUserJoined = null;
    _agoraService.onUserOffline = null;
    _agoraService.onConnectionStateChanged = null;

    if (_context.mounted) {
      canPop = true;
      Navigator.of(_context).pop();
    }
  }

  void _showError(String message) {
    if (_isDisposed || !_context.mounted) return;
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      WakelockPlus.disable();
      _callTimer?.cancel();
      _unansweredTimer?.cancel();
      ActiveCallState.clearActiveCall();
      _agoraService.leaveChannel();
      FlutterCallkitIncoming.endAllCalls();
      SocketService.instance.emit('call:end', {
        'chatId': chatId,
        'toUserId': otherUserId,
        'fromUserId': _currentUserId,
        'uuid': uuid,
      });
      _agoraService.onUserJoined = null;
      _agoraService.onUserOffline = null;
      _agoraService.onConnectionStateChanged = null;
    }
    super.dispose();
  }
}

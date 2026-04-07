import 'package:docmobi/services/callkit_service.dart';
// UPDATED - uses SharedPreferences for userId instead of API call
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/agora_service.dart';
import '../../../services/agora_chat_service.dart';
import '../../../services/active_call_state.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/callkit_service.dart';
import '../../../services/notification_api_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class AudioCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid; // Added UUID for precise termination

  const AudioCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
    this.uuid,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final AgoraService _agoraService = AgoraService.instance;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;

  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;
  bool _channelJoined = false;

  Timer? _timer;
  int _callDuration = 0;
  Timer? _unansweredTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _loadCurrentUserIdAndInitialize();
  }

  Future<void> _loadCurrentUserIdAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentUserId = prefs.getString('user_id');

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        debugPrint('User ID from cache: $_currentUserId');
        await _initializeCall();
      } else {
        debugPrint('User ID not cached, fetching from API...');
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
      if (mounted) _showError('Failed to initialize: $e');
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;

    try {
      setState(() => _callStatus = 'Setting up audio...');

      if (_currentUserId != null) {
        if (!SocketService.instance.isConnected) {
          debugPrint(
            ' Socket disconnected in AudioCallScreen - Reconnecting...',
          );
          await SocketService.instance.connect(_currentUserId!);
        } else {
          SocketService.instance.socket?.emit('joinUserRoom', _currentUserId!);
        }
      }

      await ActiveCallState.saveActiveCall(
        chatId: widget.chatId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        otherUserId: widget.otherUserId,
        isInitiator: widget.isInitiator,
        callType: 'audio',
      );

      await _agoraService.initialize();

      _agoraService.onUserJoined = (uid, elapsed) {
        if (mounted) {
          setState(() {
            _callConnected = true;
            _callStatus = 'Connected';
          });
          _startTimer();
        }
      };

      _agoraService.onUserOffline = (uid, reason) {
        if (mounted) {
          debugPrint('Remote user offline');
          _endCall();
        }
      };

      // ✅ RECOVER REMOTE USERS (iOS Lock Screen Fix)
      if (_agoraService.remoteUids.isNotEmpty) {
        debugPrint(' [Audio] Recovering existing remote user');
        if (mounted) {
          setState(() {
            _callConnected = true;
            _callStatus = 'Connected';
          });
          _startTimer();
        }
      }

      _setupSocketListeners();

      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        _unansweredTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && !_callConnected) {
            debugPrint(
              ' Audio call not answered in 30 seconds, auto-ending...',
            );
            _showError('No answer');
          }
        });
      } else {
        await _joinAgoraChannel();
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _joinAgoraChannel() async {
    if (_channelJoined) {
      debugPrint('Already joined/joining channel — skipping duplicate');
      return;
    }
    _channelJoined = true;

    try {
      setState(() => _callStatus = 'Securing connection...');

      String? token = CallKitService.consumeCachedAgoraToken();

      if (token != null) {
        debugPrint(' Using pre-fetched Agora token — no API delay!');
      } else {
        debugPrint(' No cached token, fetching from API...');
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            final result = await ApiService.getAgoraToken(
              channelName: widget.chatId,
            ).timeout(const Duration(seconds: 8));
            token = (result['success'] == true)
                ? result['data']['token']
                : null;
            if (token != null) break;
          } catch (e) {
            debugPrint(' Token fetch attempt ${attempt + 1} failed: $e');
            if (attempt == 0) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        }
      }

      if (token == null) {
        if (mounted) _showError('Connection security failed');
        return;
      }

      // ✅ CHECK FOR BACKGROUND CONNECTION (iOS Lock Screen Fix)
      if (_agoraService.currentChannel == widget.chatId) {
        debugPrint(' [Audio] App foregrounded — reusing background connection');
        if (mounted) {
          setState(() {
            _callStatus = 'Connected';
            _callConnected = true;
          });
          _startTimer();
        }
        return;
      }

      if (_currentUserId != null) {
        await _agoraService.joinChannelWithUserAccount(
          channelName: widget.chatId,
          userAccount: _currentUserId!,
          isVideo: false,
          token: token,
        );
        debugPrint(
          'Joined Agora channel (Audio) with User Account: $_currentUserId',
        );
      } else {
        await _agoraService.joinChannel(
          channelName: widget.chatId,
          uid: 0,
          isVideo: false,
          token: token,
        );
        debugPrint(' Joined Agora channel with UID 0 (Fallback)');
      }

      if (mounted) {
        setState(() {
          _callStatus = 'Connected';
          _callConnected = true;
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint(' Failed to join: $e');
      if (mounted) _showError('Failed to connect: $e');
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
      if (data['chatId'] == widget.chatId && !_channelJoined) {
        _unansweredTimer?.cancel();
        _unansweredTimer = null;
        setState(() => _callStatus = 'Connecting...');
        await _joinAgoraChannel();
      }
    }

    socket.on('call:accepted', handleCallAccepted);
    socket.on('call:accept', handleCallAccepted);

    socket.on('call:ended', (data) {
      if (data['chatId'] == widget.chatId) {
        _endCall();
      }
    });

    socket.on('call:rejected', (data) {
      if (data['chatId'] == widget.chatId) {
        debugPrint(' [Socket] Audio call rejected by recipient');
        if (mounted) {
          _showError('Call declined');
          // Wait 1 second so the user can see the "Call declined" message before closing
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _endCall();
          });
        }
      }
    });
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      } else {
        timer.cancel();
      }
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraService.toggleAudio(_isMuted);
  }

  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _agoraService.engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _endCall() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _timer?.cancel();

    await ActiveCallState.clearActiveCall();

    try {
      if (widget.otherUserId.isNotEmpty && widget.isInitiator) {
        String status = _callConnected ? 'ended' : 'cancelled';
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.otherUserId,
          callType: 'audio',
          status: status,
          duration: _callConnected ? _formatDuration(_callDuration) : '',
          backendChatId: widget.chatId,
          uuid: widget.uuid, // ✅ Pass UUID for CallKit sync
        );
      }
    } catch (e) {
      debugPrint(' Failed to send call log: $e');
    }

    await FlutterCallkitIncoming.endAllCalls();

    try {
      // ✅ Trigger backend API to send Call Cancel push
      await ApiService.endCall(
        chatId: widget.chatId,
        toUserId: widget.otherUserId,
        uuid: widget.uuid, // Pass UUID back to backend
      );
    } catch (e) {
      debugPrint(' API endCall error, falling back to socket: $e');
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
        'fromUserId': _currentUserId,
        'uuid': widget.uuid, // Also add to socket emit
      });
    }

    await _agoraService.leaveChannel();

    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing AudioCallScreen');
    WakelockPlus.disable();
    _unansweredTimer?.cancel();
    _timer?.cancel();

    if (!_isDisposed) {
      debugPrint(' AudioCallScreen disposed without _endCall — cleaning up');
      _isDisposed = true;
      ActiveCallState.clearActiveCall();
      _agoraService.leaveChannel();
      FlutterCallkitIncoming.endAllCalls();
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
        'fromUserId': _currentUserId,
        'uuid': widget.uuid,
      });
    }

    _agoraService.onUserJoined = null;
    _agoraService.onUserOffline = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _endCall();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 80,
                  backgroundImage: widget.userAvatar != null
                      ? NetworkImage(widget.userAvatar!)
                      : const AssetImage('assets/images/doctor.png')
                            as ImageProvider,
                ),
                const SizedBox(height: 30),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _callConnected ? _formatDuration(_callDuration) : _callStatus,
                  style: TextStyle(
                    color: _callConnected ? Colors.greenAccent : Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onPressed: _toggleMute,
                        backgroundColor: _isMuted
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label: 'Speaker',
                        onPressed: _toggleSpeaker,
                        backgroundColor: _isSpeakerOn
                            ? Colors.blue
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                IconButton(
                  iconSize: 60,
                  icon: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  onPressed: _endCall,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

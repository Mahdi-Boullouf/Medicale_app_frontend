import 'package:docmobi/services/callkit_service.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
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

class VideoCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid; // Added for precise termination

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
    this.uuid,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService.instance;

  int? _remoteUid;

  bool _isMuted = false;
  bool _isVideoOff = false;
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
        debugPrint(' User ID from cache: $_currentUserId');
        await _initializeCall();
      } else {
        debugPrint(' User ID not cached, fetching from API...');
        final profileResult = await ApiService.getUserProfile();
        if (profileResult['success'] == true) {
          _currentUserId = profileResult['data']['_id']?.toString();
          if (_currentUserId != null) {
            await prefs.setString('user_id', _currentUserId!);
          }
          debugPrint(' User ID loaded: $_currentUserId');
          await _initializeCall();
        } else {
          throw Exception('Failed to load user profile');
        }
      }
    } catch (e) {
      debugPrint(' Error loading user ID: $e');
      if (mounted) {
        _showError('Failed to initialize: $e');
      }
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;

    try {
      setState(() => _callStatus = 'Setting up video...');

      await ActiveCallState.saveActiveCall(
        chatId: widget.chatId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        otherUserId: widget.otherUserId,
        isInitiator: widget.isInitiator,
        callType: 'video',
      );

      await _agoraService.initialize();

      _agoraService.onUserJoined = (uid, elapsed) {
        if (mounted) {
          debugPrint(' Remote user joined: $uid');
          setState(() {
            _remoteUid = uid;
            _isCallConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      };

      _agoraService.onUserOffline = (uid, reason) {
        if (mounted) {
          debugPrint('Remote user offline: $reason');
          setState(() {
            _remoteUid = null;
            _callStatus = 'User Offline';
          });
        }
      };

      // ✅ RECOVER REMOTE USERS (iOS Lock Screen Fix)
      // Callers who joined while the recipient was locked/in-background won't trigger onUserJoined again.
      if (_agoraService.remoteUids.isNotEmpty) {
        final existingUid = _agoraService.remoteUids.first;
        debugPrint(' [Video] Recovering existing remote user: $existingUid');
        if (mounted) {
          setState(() {
            _remoteUid = existingUid;
            _isCallConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      }

      _agoraService.onLeaveChannel = (stats) {
        debugPrint('I left the channel');
      };

      _agoraService.onConnectionStateChanged = (state, reason) {
        if (!mounted) return;
        debugPrint(' Connection State: $state, Reason: $reason');

        setState(() {
          if (state == ConnectionStateType.connectionStateReconnecting) {
            _callStatus = 'Reconnecting...';
          } else if (state == ConnectionStateType.connectionStateFailed) {
            _callStatus = 'Connection Failed';
            _showError('Connection failed: $reason');
            _endCall();
          } else if (state == ConnectionStateType.connectionStateConnected) {
            _callStatus = _isCallConnected
                ? (_callDuration.isEmpty ? 'Connected' : _callDuration)
                : 'Connected';
          }
        });
      };

      if (_currentUserId != null) {
        if (!SocketService.instance.isConnected) {
          debugPrint(
            ' Socket disconnected in VideoCallScreen - Reconnecting...',
          );
          await SocketService.instance.connect(_currentUserId!);
        } else {
          SocketService.instance.socket?.emit('joinUserRoom', _currentUserId!);
        }
      }

      _setupSocketListeners();

      setState(() {
        _isInitializing = false;
      });

      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        _unansweredTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && !_isCallConnected) {
            debugPrint(' Call not answered in 30 seconds, auto-ending...');
            _showError('No answer');
          }
        });
      } else {
        debugPrint('Receiver joining channel immediately...');
        await _joinAgoraChannel();
      }
    } catch (e) {
      debugPrint('Error initializing call: $e');
      _showError('Failed to start call: $e');
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
        debugPrint(
          ' [Video] App foregrounded — upgrading audio-only background connection to Video',
        );
        await _agoraService.engine?.enableVideo();
        await _agoraService.engine?.startPreview();

        if (mounted) {
          setState(() {
            // ✅ Pick up remote user if they already joined in the background
            if (_agoraService.remoteUids.isNotEmpty) {
              _remoteUid = _agoraService.remoteUids.first;
              _isCallConnected = true;
              _callStatus = 'Connected';
            } else {
              _callStatus = 'Connected';
              _isCallConnected = true;
            }
          });
          if (_isCallConnected) _startCallTimer();
        }
        return;
      }

      if (_currentUserId != null) {
        await _agoraService.joinChannelWithUserAccount(
          channelName: widget.chatId,
          userAccount: _currentUserId!,
          isVideo: true,
          token: token,
        );
        debugPrint('Joined Agora channel with User Account: $_currentUserId');
      } else {
        await _agoraService.joinChannel(
          channelName: widget.chatId,
          uid: 0,
          isVideo: true,
          token: token,
        );
        debugPrint('Joined Agora channel with UID 0 (Fallback)');
      }

      if (mounted) {
        setState(() {
          _callStatus = 'Connected';
          _isCallConnected = true;
        });
        _startCallTimer();
      }
    } catch (e) {
      debugPrint('Failed to join channel: $e');
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
      debugPrint('Received call accepted event');
      if (data['chatId'] == widget.chatId && !_channelJoined) {
        debugPrint(' Call accepted, joining Agora channel...');
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
        debugPrint(' Call ended by remote user');
        _endCall();
      }
    });

    socket.on('call:rejected', (data) {
      if (data['chatId'] == widget.chatId) {
        debugPrint(' [Socket] Call rejected by recipient');
        if (mounted) {
          _showError('Call declined');
          // Wait 1 second so the user can see the "Call declined" message before closing
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _endCall();
          });
        }
      }
    });

    socket.on('call:switch_request', (data) {
      if (data['chatId'] == widget.chatId && mounted) {}
    });
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
          final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(
            2,
            '0',
          );
          final seconds = (_callDurationSeconds % 60).toString().padLeft(
            2,
            '0',
          );
          _callDuration = '$minutes:$seconds';
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraService.toggleAudio(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoOff = !_isVideoOff);
    _agoraService.toggleVideo(_isVideoOff);
  }

  void _switchCamera() {
    _agoraService.switchCamera();
  }

  void _endCall() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _callTimer?.cancel();

    await ActiveCallState.clearActiveCall();

    try {
      if (widget.otherUserId.isNotEmpty && widget.isInitiator) {
        String status = _isCallConnected ? 'ended' : 'cancelled';
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.otherUserId,
          callType: 'video',
          status: status,
          duration: _isCallConnected ? _callDuration : '',
          backendChatId: widget.chatId,
          uuid: widget.uuid, // ✅ Pass UUID for CallKit sync
        );
      }
    } catch (e) {
      debugPrint(' Failed to send call log: $e');
    }

    await FlutterCallkitIncoming.endAllCalls();

    try {
      // ✅ Properly trigger backend API so it sends Call Cancellation push to offline receiver
      await ApiService.endCall(
        chatId: widget.chatId,
        toUserId: widget.otherUserId,
        uuid: widget.uuid, // Pass UUID to backend
      );
    } catch (e) {
      debugPrint(' API endCall error, falling back to socket: $e');
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
        'fromUserId': _currentUserId,
        'uuid': widget.uuid, // Pass UUID to socket
      });
    }

    await _agoraService.leaveChannel();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing VideoCallScreen');
    WakelockPlus.disable();
    _callTimer?.cancel();
    _unansweredTimer?.cancel();

    if (!_isDisposed) {
      debugPrint(' VideoCallScreen disposed without _endCall — cleaning up');
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
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote Video (Full Screen)
            if (_remoteUid != null)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _agoraService.engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.chatId),
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFF1B2C49),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            widget.userAvatar != null &&
                                widget.userAvatar!.isNotEmpty
                            ? NetworkImage(widget.userAvatar!)
                            : const AssetImage('assets/images/doctor1.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _callStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      if (_isInitializing ||
                          _callStatus == 'Calling...' ||
                          _callStatus == 'Connecting...')
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),

            // Local Video (Small View)
            if (!_isVideoOff && _agoraService.engine != null)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _agoraService.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // Header Info
            Positioned(
              top: 50,
              left: 20,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            widget.userAvatar != null &&
                                widget.userAvatar!.isNotEmpty
                            ? NetworkImage(widget.userAvatar!)
                            : const AssetImage('assets/images/doctor1.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _isCallConnected ? _callDuration : _callStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onPressed: _toggleMute,
                        color: _isMuted ? Colors.red : Colors.white,
                      ),
                      _buildControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        label: _isVideoOff ? 'Cam Off' : 'Cam On',
                        onPressed: _toggleVideo,
                        color: _isVideoOff ? Colors.red : Colors.white,
                      ),
                      _buildControlButton(
                        icon: Icons.cameraswitch,
                        label: 'Switch',
                        onPressed: _switchCamera,
                        color: Colors.white,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        label: 'End',
                        onPressed: _endCall,
                        color: Colors.red,
                        isEndCall: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEndCall
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

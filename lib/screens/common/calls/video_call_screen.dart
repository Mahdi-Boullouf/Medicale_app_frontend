import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/agora_service.dart';
import '../../../services/agora_chat_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Agora Service
  final AgoraService _agoraService = AgoraService.instance;

  int? _remoteUid; // Track the remote user's Agora UID

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isCallConnected = false;
  bool _isInitializing = true;
  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;

  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _callDuration = '00:00';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _loadCurrentUserIdAndInitialize();
  }

  Future<void> _loadCurrentUserIdAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ignore: unused_local_variable
      final userDataString = prefs.getString('user_data');

      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        _currentUserId = profileResult['data']['_id']?.toString();
        debugPrint('✅ Current user ID loaded: $_currentUserId');

        // Initialize Call
        await _initializeCall();
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      debugPrint('❌ Error loading user ID: $e');
      if (mounted) {
        _showError('Failed to initialize: $e');
      }
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;

    try {
      setState(() => _callStatus = 'Setting up video...');

      // 1. Initialize Agora
      await _agoraService.initialize();

      // 2. Setup Agora Listeners
      _agoraService.onUserJoined = (uid, elapsed) {
        if (mounted) {
          debugPrint('✅ Remote user joined: $uid');
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
          // Optional: Don't end call immediately if it's just a temporary drop, but for now we end it or show waiting
          // _endCall();
          setState(() {
            _remoteUid = null;
            _callStatus = 'User Offline';
          });
        }
      };

      _agoraService.onLeaveChannel = (stats) {
        debugPrint('I left the channel');
      };

      // 3. Setup Socket Listeners (for strict signaling like End Call)
      _setupSocketListeners();

      setState(() {
        _isInitializing = false;
      });

      // 4. Join Channel
      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        // Wait for 'call:accepted' event before joining to avoid joining empty channel
      } else {
        // Receiver joins immediately
        debugPrint('📥 Receiver joining channel immediately...');
        await _joinAgoraChannel();
      }
    } catch (e) {
      debugPrint('❌ Error initializing call: $e');
      _showError('Failed to start call: $e');
    }
  }

  Future<void> _joinAgoraChannel() async {
    try {
      setState(() => _callStatus = 'Securing connection...');

      // ✅ Fetch Dynamic Token
      final result = await ApiService.getAgoraToken(channelName: widget.chatId);
      final String? token = (result['success'] == true)
          ? result['data']['token']
          : null;

      if (token == null) {
        if (mounted) _showError('Connection security failed');
        return;
      }
      debugPrint('🔐 Call Token Secured');

      // Use chatId as channel name
      await _agoraService.joinChannel(
        channelName: widget.chatId,
        uid: 0,
        isVideo: true,
        token: token, // Pass dynamic token
      );
      debugPrint('✅ Joined Agora channel: ${widget.chatId}');
    } catch (e) {
      debugPrint('❌ Failed to join channel: $e');
      _showError('Failed to connect to call');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    // Cleanup first
    socket.off('call:accepted');
    socket.off('call:ended');
    socket.off('call:rejected');

    socket.on('call:accepted', (data) async {
      debugPrint('📥 Received call:accepted event');
      if (data['chatId'] == widget.chatId) {
        debugPrint('✅ Call accepted, joining Agora channel...');
        setState(() => _callStatus = 'Connecting...');
        await _joinAgoraChannel();
      }
    });

    socket.on('call:ended', (data) {
      if (data['chatId'] == widget.chatId) {
        debugPrint('📴 Call ended by remote user');
        _endCall();
      }
    });

    socket.on('call:rejected', (data) {
      if (data['chatId'] == widget.chatId) {
        _showError('Call declined');
      }
    });

    socket.on('call:switch_request', (data) {
      if (data['chatId'] == widget.chatId && mounted) {
        // Handle switch request if needed (e.g. audio to video)
      }
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

    // ✅ Log Call to Chat (Initiator Only to prevent duplicates)
    try {
      if (widget.otherUserId.isNotEmpty && widget.isInitiator) {
        String status = _isCallConnected ? 'ended' : 'cancelled';
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.otherUserId,
          callType: 'video',
          status: status,
          duration: _isCallConnected ? _callDuration : '',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send call log: $e');
    }

    // Notify server
    SocketService.instance.emit('call:end', {
      'chatId': widget.chatId,
      'toUserId': widget.otherUserId,
      'fromUserId': _currentUserId,
    });

    // Leave Agora
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

    final socket = SocketService.instance.socket;
    socket?.off('call:accepted');
    socket?.off('call:ended');
    socket?.off('call:rejected');

    _agoraService.leaveChannel();

    // Clear callbacks to avoid calling setState on disposed widget
    _agoraService.onUserJoined = null;
    _agoraService.onUserOffline = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
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
              // Waiting for remote user
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

            // Local Video (Small View) - Only if video is ON
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
                        color: Colors.black.withOpacity(0.3),
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
                        canvas: const VideoCanvas(uid: 0), // 0 for local view
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
                    color: Colors.black.withOpacity(0.5),
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
              color: isEndCall ? Colors.red : Colors.white.withOpacity(0.2),
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

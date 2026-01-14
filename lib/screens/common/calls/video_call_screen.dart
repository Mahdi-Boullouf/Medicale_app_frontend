import 'package:docmobi/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/webrtc_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  WebRTCService? _webRTCService;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isCallConnected = false;
  bool _isInitializing = true;
  String _callStatus = 'Connecting...';
  String? _currentUserId;
  
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _callDuration = '00:00';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserIdAndInitialize();
  }

  // ✅ Load current user ID first, then initialize call
  Future<void> _loadCurrentUserIdAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      // Try to get from API
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        _currentUserId = profileResult['data']['_id']?.toString();
        print('✅ Current user ID loaded: $_currentUserId');
        
        // Now initialize the call
        await _initializeCall();
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initializeCall() async {
    try {
      print('🎥 Initializing video call...');
      print('💬 Chat ID: ${widget.chatId}');
      print('👤 Other user: ${widget.otherUserId}');
      print('👤 Current user: $_currentUserId');
      print('🎬 Is Initiator: ${widget.isInitiator}');
      
      // Initialize renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      print('✅ Renderers initialized');

      // Initialize WebRTC service
      _webRTCService = WebRTCService(
        socket: SocketService.instance.socket!,
        chatId: widget.chatId,
        isVideo: true,
        onRemoteStream: (stream) {
          print('📹 Remote stream received in callback!');
          if (mounted) {
            setState(() {
              _remoteRenderer.srcObject = stream;
              _isCallConnected = true;
              _callStatus = 'Connected';
            });
            
            // ✅ Start timer when remote stream is received
            if (!_isTimerRunning()) {
              _startCallTimer();
            }
          }
        },
        onCallEnded: () {
          print('📴 Call ended callback triggered');
          _endCall();
        },
      );

      // ✅ Set current user ID in WebRTC service
      _webRTCService!.setCurrentUserId(_currentUserId!);

      await _webRTCService!.initialize();
      print('✅ WebRTC service initialized');

      // Set local stream
      setState(() {
        _localRenderer.srcObject = _webRTCService!.localStream;
        _isInitializing = false;
        _callStatus = widget.isInitiator ? 'Calling...' : 'Connecting...';
      });
      print('✅ Local stream set');

      // Setup socket listeners
      _setupSocketListeners();

      // If initiator, create offer
      if (widget.isInitiator) {
        print('📤 Creating offer as initiator...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _webRTCService!.createOffer(widget.otherUserId);
      } else {
        print('📥 Waiting for offer as receiver...');
      }
    } catch (e) {
      print('❌ Error initializing call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) {
      print('⚠️ Socket is null in _setupSocketListeners');
      return;
    }

    print('👂 Setting up socket listeners for chat: ${widget.chatId}');

    socket.on('call:offer', (data) async {
      print('📥 Received call:offer event: $data');
      if (data['chatId'] == widget.chatId) {
        print('✅ Offer is for this chat, handling...');
        final fromUserId = data['fromUserId'] ?? widget.otherUserId;
        await _webRTCService?.handleOffer(data['offer'], fromUserId);
      }
    });

    socket.on('call:answer', (data) async {
      print('📥 Received call:answer event: $data');
      if (data['chatId'] == widget.chatId) {
        print('✅ Answer is for this chat, handling...');
        await _webRTCService?.handleAnswer(data['answer']);
        
        setState(() {
          _callStatus = 'Connected';
          _isCallConnected = true;
        });
        
        // ✅ Start timer when answer is received (for initiator)
        if (!_isTimerRunning()) {
          _startCallTimer();
        }
      }
    });

    socket.on('call:iceCandidate', (data) async {
      print('📥 Received ICE candidate: ${data['candidate']}');
      if (data['chatId'] == widget.chatId) {
        await _webRTCService?.addIceCandidate(data['candidate']);
      }
    });

    socket.on('call:ended', (data) {
      print('📥 Received call:ended event');
      if (data['chatId'] == widget.chatId) {
        print('📴 Call ended by remote user');
        _endCall();
      }
    });

    socket.on('call:rejected', (data) {
      print('📥 Received call:rejected event');
      if (data['chatId'] == widget.chatId) {
        print('❌ Call was rejected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call was rejected')),
          );
          Navigator.pop(context);
        }
      }
    });
    
    socket.on('call:accepted', (data) {
      print('📥 Received call:accepted event');
      if (data['chatId'] == widget.chatId) {
        print('✅ Call was accepted by receiver');
        setState(() {
          _callStatus = 'Connecting...';
        });
      }
    });
    
    print('✅ All socket listeners set up');
  }

  // ✅ Check if timer is running
  bool _isTimerRunning() {
    return _callTimer != null && _callTimer!.isActive;
  }

  // ✅ Start call timer
  void _startCallTimer() {
    if (_isTimerRunning()) {
      print('⏱️ Timer already running');
      return;
    }
    
    print('⏱️ Starting call timer');
    _callTimer?.cancel();
    _callDurationSeconds = 0; // Reset to 0
    
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
          final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
          _callDuration = '$minutes:$seconds';
        });
        print('⏱️ Call duration: $_callDuration');
      } else {
        timer.cancel();
      }
    });
    
    print('✅ Call timer started');
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _webRTCService?.toggleAudio();
    print('🎤 Audio ${_isMuted ? "muted" : "unmuted"}');
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _webRTCService?.toggleVideo();
    print('📹 Video ${_isVideoOff ? "disabled" : "enabled"}');
  }

  void _endCall() {
    print('📴 Ending call...');
    
    _callTimer?.cancel();
    _callTimer = null;
    
    SocketService.instance.emit('call:end', {
      'chatId': widget.chatId,
      'toUserId': widget.otherUserId,
      'fromUserId': _currentUserId,
    });

    _webRTCService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    
    print('✅ Call ended, navigating back');
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isCallConnected)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: false,
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
                        backgroundImage: widget.userAvatar != null &&
                                widget.userAvatar!.isNotEmpty &&
                                widget.userAvatar != 'file:///' &&
                                (widget.userAvatar!.startsWith('http://') ||
                                    widget.userAvatar!.startsWith('https://'))
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
                        _isCallConnected ? _callDuration : _callStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      if (_isInitializing)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            if (!_isVideoOff)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      _localRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.userAvatar != null &&
                              widget.userAvatar!.isNotEmpty &&
                              widget.userAvatar != 'file:///' &&
                              (widget.userAvatar!.startsWith('http://') ||
                                  widget.userAvatar!.startsWith('https://'))
                          ? NetworkImage(widget.userAvatar!)
                          : const AssetImage('assets/images/doctor1.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isCallConnected ? _callDuration : _callStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
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
                      label: _isVideoOff ? 'Turn On' : 'Turn Off',
                      onPressed: _toggleVideo,
                      color: _isVideoOff ? Colors.red : Colors.white,
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
        Container(
          width: isEndCall ? 70 : 60,
          height: isEndCall ? 70 : 60,
          decoration: BoxDecoration(
            color: isEndCall ? Colors.red : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: isEndCall ? 32 : 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('🧹 Disposing VideoCallScreen');
    
    _callTimer?.cancel();
    _callTimer = null;
    
    _webRTCService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    
    final socket = SocketService.instance.socket;
    socket?.off('call:offer');
    socket?.off('call:answer');
    socket?.off('call:iceCandidate');
    socket?.off('call:ended');
    socket?.off('call:rejected');
    socket?.off('call:accepted');
    
    print('✅ VideoCallScreen disposed');
    
    super.dispose();
  }
}

// ✅ Import for API service

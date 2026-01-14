import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/webrtc_service.dart';

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
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  bool _callConnected = false;
  bool _isDisposed = false;
  Timer? _callTimer;
  int _callDuration = 0;
  String? _currentUserId;
  String _callStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      await _loadCurrentUserId();
      
      if (_currentUserId == null) {
        _showError('Failed to get user ID');
        return;
      }

      setState(() {
        _callStatus = 'Setting up video...';
      });

      print('📹 Initializing video call...');
      print('   • Chat ID: ${widget.chatId}');
      print('   • Other User: ${widget.otherUserId}');
      print('   • Is Initiator: ${widget.isInitiator}');
      print('   • Current User: $_currentUserId');

      final socket = SocketService.instance.socket;
      if (socket == null || !SocketService.instance.isConnected) {
        throw Exception('Socket not connected');
      }

      _webRTCService = WebRTCService(
        chatId: widget.chatId,
        isVideo: true,
        onRemoteStream: (stream) {
          if (mounted && !_isDisposed) {
            print('✅ Remote video stream received - call connected!');
            setState(() {
              _remoteRenderer.srcObject = stream;
              _callConnected = true;
              _callStatus = 'Connected';
            });
            _startCallTimer();
          }
        },
        onCallEnded: () {
          print('📴 Call ended by peer');
          _endCall();
        },
      );

      await _webRTCService!.initialize();
      _webRTCService!.setCurrentUserId(_currentUserId!);
      
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = _webRTCService!.localStream;
        });
      }

      print('✅ WebRTC initialized');

      _setupSocketListeners();

      setState(() {
        _callStatus = widget.isInitiator ? 'Calling...' : 'Connecting...';
      });

      if (widget.isInitiator) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted && !_isDisposed) {
          print('📤 Creating offer as initiator...');
          await _webRTCService!.createOffer(widget.otherUserId);
          print('✅ Offer created and sent');
        }
      }
    } catch (e) {
      print('❌ Error initializing call: $e');
      _showError('Failed to start call: $e');
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true && mounted) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
        });
        print('✅ Current user ID loaded: $_currentUserId');
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    socket.off('call:offer');
    socket.off('call:answer');
    socket.off('call:iceCandidate');
    socket.off('call:end');

    socket.on('call:offer', (data) async {
      print('📥 Received offer: $data');
      if (data['chatId'] == widget.chatId && mounted && !_isDisposed) {
        final fromUserId = data['fromUserId']?.toString();
        if (fromUserId != null && _webRTCService != null) {
          setState(() {
            _callStatus = 'Connecting...';
          });
          await _webRTCService!.handleOffer(data['offer'], fromUserId);
        }
      }
    });

    socket.on('call:answer', (data) async {
      print('📥 Received answer: $data');
      if (data['chatId'] == widget.chatId && mounted && !_isDisposed) {
        if (_webRTCService != null) {
          await _webRTCService!.handleAnswer(data['answer']);
          setState(() {
            _callStatus = 'Establishing connection...';
          });
        }
      }
    });

    socket.on('call:iceCandidate', (data) async {
      print('📥 Received ICE candidate');
      if (data['chatId'] == widget.chatId && mounted && !_isDisposed) {
        if (_webRTCService != null) {
          await _webRTCService!.addIceCandidate(data['candidate']);
        }
      }
    });

    socket.on('call:end', (data) {
      print('📥 Received call:end event');
      if (data['chatId'] == widget.chatId && mounted && !_isDisposed) {
        _endCall();
      }
    });

    print('✅ Socket listeners setup complete');
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isDisposed) {
        setState(() {
          _callDuration++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    if (_webRTCService != null && mounted && !_isDisposed) {
      setState(() {
        _isMuted = !_isMuted;
      });
      _webRTCService!.toggleAudio();
    }
  }

  void _toggleVideo() {
    if (_webRTCService != null && mounted && !_isDisposed) {
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
      _webRTCService!.toggleVideo();
    }
  }

  Future<void> _switchCamera() async {
    if (_webRTCService == null || !_isVideoEnabled || _isDisposed) return;
    
    try {
      final videoTrack = _webRTCService!.localStream?.getVideoTracks().first;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      }
    } catch (e) {
      print('❌ Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch camera')),
        );
      }
    }
  }

  void _endCall() {
    if (_isDisposed) return;
    
    print('📴 Ending call...');
    
    _callTimer?.cancel();
    _callTimer = null;
    
    if (SocketService.instance.isConnected) {
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
      });
    }
    
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
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
            // Remote video (full screen)
            if (_callConnected)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              // Connecting state
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: widget.userAvatar != null
                          ? NetworkImage(widget.userAvatar!)
                          : const AssetImage('assets/images/doctor.png') as ImageProvider,
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
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),

            // Local video preview (small box)
            if (_isVideoEnabled)
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
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: _isFrontCamera,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // User name badge with duration
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_callConnected)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (_callConnected) const SizedBox(width: 8),
                    Text(
                      _callConnected 
                          ? '${widget.userName} - ${_formatDuration(_callDuration)}'
                          : widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted 
                        ? Colors.red 
                        : Colors.white.withOpacity(0.3),
                  ),
                  
                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                  ),
                  
                  // Video toggle button
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    onPressed: _toggleVideo,
                    backgroundColor: _isVideoEnabled 
                        ? Colors.white.withOpacity(0.3) 
                        : Colors.red,
                  ),
                  
                  // Camera switch button
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    onPressed: _isVideoEnabled ? _switchCamera : null,
                    backgroundColor: _isVideoEnabled
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('🧹 Disposing VideoCallScreen');
    
    _isDisposed = true;
    
    WakelockPlus.disable();
    
    _callTimer?.cancel();
    _callTimer = null;
    
    _webRTCService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    
    final socket = SocketService.instance.socket;
    socket?.off('call:offer');
    socket?.off('call:answer');
    socket?.off('call:iceCandidate');
    socket?.off('call:end');
    
    print('✅ VideoCallScreen disposed');
    
    super.dispose();
  }
}

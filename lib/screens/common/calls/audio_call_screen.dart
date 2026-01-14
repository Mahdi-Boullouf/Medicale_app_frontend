import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/webrtc_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;

  const AudioCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  WebRTCService? _webRTCService;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;
  Timer? _callTimer;
  int _callDuration = 0;
  String? _currentUserId;
  bool _isDisposed = false;
  String _callStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _loadCurrentUserId();
      
      if (_currentUserId == null) {
        _showError('Failed to get user ID');
        return;
      }
      
      setState(() {
        _callStatus = 'Setting up audio...';
      });

      print('🎙️ Initializing audio call...');
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
        isVideo: false,
        onRemoteStream: (stream) {
          if (mounted && !_isDisposed) {
            print('✅ Remote audio stream received - call connected!');
            setState(() {
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

  void _toggleSpeaker() {
    if (mounted && !_isDisposed) {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
      // Note: Actual speaker toggle requires platform-specific implementation
      print('🔊 Speaker ${_isSpeakerOn ? "ON" : "OFF"}');
    }
  }

  void _endCall() {
    if (_isDisposed) return;
    
    print('📴 Ending call...');
    
    _callTimer?.cancel();
    _callTimer = null;
    
    // Emit call end event
    if (SocketService.instance.isConnected) {
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
      });
    }
    
    // Safe navigation pop
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
        backgroundColor: const Color(0xFF1B2C49),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // User Avatar
              CircleAvatar(
                radius: 80,
                backgroundImage: widget.userAvatar != null
                    ? NetworkImage(widget.userAvatar!)
                    : const AssetImage('assets/images/doctor.png') as ImageProvider,
              ),
              
              const SizedBox(height: 30),
              
              // User Name
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Call Status
              Text(
                _callConnected 
                    ? _formatDuration(_callDuration)
                    : _callStatus,
                style: TextStyle(
                  color: _callConnected ? Colors.greenAccent : Colors.white70,
                  fontSize: 18,
                ),
              ),
              
              if (!_callConnected)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              
              const Spacer(),
              
              // Call Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted 
                        ? Colors.red 
                        : Colors.white.withOpacity(0.3),
                  ),
                  
                  // End Call Button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 70,
                  ),
                  
                  // Speaker Button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onPressed: _toggleSpeaker,
                    backgroundColor: _isSpeakerOn 
                        ? Colors.blue 
                        : Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
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
          size: size * 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('🧹 Disposing AudioCallScreen');
    
    _isDisposed = true;
    
    WakelockPlus.disable();
    
    _callTimer?.cancel();
    _callTimer = null;
    
    _webRTCService?.dispose();
    
    final socket = SocketService.instance.socket;
    socket?.off('call:offer');
    socket?.off('call:answer');
    socket?.off('call:iceCandidate');
    socket?.off('call:end');
    
    print('✅ AudioCallScreen disposed');
    
    super.dispose();
  }
}

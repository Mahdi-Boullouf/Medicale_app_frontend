import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:docmobi/services/webrtc_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  WebRTCService? _webrtcService;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;
  String _callDuration = '00:00';
  Timer? _timer;
  int _seconds = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _loadCurrentUserIdAndInitialize();
  }

  // ✅ Load current user ID first
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
      print('🎤 Initializing audio call...');
      print('💬 Chat ID: ${widget.chatId}');
      print('👤 Other user: ${widget.otherUserId}');
      print('👤 Current user: $_currentUserId');
      print('🎬 Is Initiator: ${widget.isInitiator}');
      
      final socket = SocketService.instance.socket;
      if (socket == null) {
        throw Exception('Socket not connected');
      }

      _webrtcService = WebRTCService(
        socket: socket,
        chatId: widget.chatId,
        isVideo: false,
        onRemoteStream: (stream) {
          print('🎵 Remote audio stream received!');
          if (mounted) {
            setState(() {
              _callConnected = true;
            });
            
            // ✅ Start timer when remote stream received
            if (!_isTimerRunning()) {
              _startTimer();
            }
          }
        },
        onCallEnded: () {
          print('📴 Call ended callback triggered');
          _endCall();
        },
      );

      // ✅ Set current user ID
      _webrtcService!.setCurrentUserId(_currentUserId!);

      await _webrtcService!.initialize();
      print('✅ WebRTC service initialized');

      _setupSocketListeners();

      if (widget.isInitiator) {
        print('📤 Creating offer as initiator...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _webrtcService!.createOffer(widget.otherUserId);
      } else {
        print('📥 Waiting for offer as receiver...');
      }
    } catch (e) {
      print('❌ Error initializing call: $e');
      _showError('Failed to start call: $e');
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
      print('📥 Received call:offer event');
      if (data['chatId'] == widget.chatId) {
        print('✅ Offer is for this chat, handling...');
        final fromUserId = data['fromUserId'] ?? widget.otherUserId;
        await _webrtcService?.handleOffer(data['offer'], fromUserId);
      }
    });

    socket.on('call:answer', (data) async {
      print('📥 Received call:answer event');
      if (data['chatId'] == widget.chatId) {
        print('✅ Answer is for this chat, handling...');
        await _webrtcService?.handleAnswer(data['answer']);
        
        if (mounted) {
          setState(() {
            _callConnected = true;
          });
          
          // ✅ Start timer when answer received (for initiator)
          if (!_isTimerRunning()) {
            _startTimer();
          }
        }
      }
    });

    socket.on('call:iceCandidate', (data) async {
      print('📥 Received ICE candidate');
      if (data['chatId'] == widget.chatId) {
        await _webrtcService?.addIceCandidate(data['candidate']);
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
      }
    });
    
    print('✅ All socket listeners set up');
  }

  // ✅ Check if timer is running
  bool _isTimerRunning() {
    return _timer != null && _timer!.isActive;
  }

  void _startTimer() {
    if (_isTimerRunning()) {
      print('⏱️ Timer already running');
      return;
    }
    
    print('⏱️ Starting call timer');
    _timer?.cancel();
    _seconds = 0; // Reset to 0
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
          final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
          final secs = (_seconds % 60).toString().padLeft(2, '0');
          _callDuration = '$minutes:$secs';
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
      _webrtcService?.toggleAudio();
    });
    print('🎤 Audio ${_isMuted ? "muted" : "unmuted"}');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    print('🔊 Speaker ${_isSpeakerOn ? "on" : "off"}');
  }

  void _endCall() {
    print('📴 Ending call...');
    
    _timer?.cancel();
    _timer = null;
    
    SocketService.instance.emit('call:end', {
      'chatId': widget.chatId,
      'toUserId': widget.otherUserId,
      'fromUserId': _currentUserId,
    });
    
    print('✅ Call ended, navigating back');
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing AudioCallScreen');
    
    WakelockPlus.disable();
    _timer?.cancel();
    _timer = null;
    _webrtcService?.dispose();
    
    SocketService.instance.off('call:offer');
    SocketService.instance.off('call:answer');
    SocketService.instance.off('call:iceCandidate');
    SocketService.instance.off('call:ended');
    SocketService.instance.off('call:rejected');
    SocketService.instance.off('call:accepted');
    
    print('✅ AudioCallScreen disposed');
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              CircleAvatar(
                radius: 80,
                backgroundImage: widget.userAvatar != null &&
                        widget.userAvatar!.isNotEmpty &&
                        widget.userAvatar != 'file:///' &&
                        (widget.userAvatar!.startsWith('http://') ||
                            widget.userAvatar!.startsWith('https://'))
                    ? NetworkImage(widget.userAvatar!)
                    : const AssetImage('assets/images/doctor.png') as ImageProvider,
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
                _callConnected ? _callDuration : 'Calling...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
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
                      backgroundColor: _isMuted ? Colors.red : Colors.white.withOpacity(0.3),
                    ),
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      onPressed: _toggleSpeaker,
                      backgroundColor: _isSpeakerOn ? Colors.blue : Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
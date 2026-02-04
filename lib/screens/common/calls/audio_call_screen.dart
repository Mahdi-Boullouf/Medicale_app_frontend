import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/agora_service.dart';
import '../../../services/agora_chat_service.dart';

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
  final AgoraService _agoraService = AgoraService.instance;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;

  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;

  Timer? _timer;
  int _callDuration = 0;

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
        await _initializeCall();
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      if (mounted) _showError('Failed to initialize: $e');
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;

    try {
      setState(() => _callStatus = 'Setting up audio...');

      await _agoraService.initialize();

      // Events
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

      _setupSocketListeners();

      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        // Wait for accept
      } else {
        await _joinAgoraChannel();
      }
    } catch (e) {
      _showError('Error: $e');
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

      // isVideo: false for audio only
      await _agoraService.joinChannel(
        channelName: widget.chatId,
        uid: 0,
        isVideo: false,
        token: token,
      );
      debugPrint('✅ Joined Agora channel (Audio Mode) with Token');
    } catch (e) {
      debugPrint('❌ Failed to join: $e');
      if (mounted) _showError('Failed to connect: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    socket.off('call:accepted');
    socket.off('call:ended');
    socket.off('call:rejected');

    socket.on('call:accepted', (data) async {
      if (data['chatId'] == widget.chatId) {
        setState(() => _callStatus = 'Connecting...');
        await _joinAgoraChannel();
      }
    });

    socket.on('call:ended', (data) {
      if (data['chatId'] == widget.chatId) {
        _endCall();
      }
    });

    socket.on('call:rejected', (data) {
      if (data['chatId'] == widget.chatId) {
        _showError('Call declined');
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
    // Use Agora engine to set speaker
    await _agoraService.engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _endCall() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _timer?.cancel();

    // ✅ Log Call to Chat (Initiator Only to prevent duplicates)
    try {
      if (widget.otherUserId.isNotEmpty && widget.isInitiator) {
        String status = _callConnected ? 'ended' : 'cancelled';
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.otherUserId,
          callType: 'audio',
          status: status,
          duration: _callConnected ? _formatDuration(_callDuration) : '',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send call log: $e');
    }

    SocketService.instance.emit('call:end', {
      'chatId': widget.chatId,
      'toUserId': widget.otherUserId,
      'fromUserId': _currentUserId,
    });

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
    _timer?.cancel();
    _agoraService.leaveChannel();

    // ⚠️ DO NOT use socket.off('event') here as it removes ALL listeners,
    // including the ones in CallManager.

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

              // Controls
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
                          : Colors.white.withOpacity(0.3),
                    ),
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      onPressed: _toggleSpeaker,
                      backgroundColor: _isSpeakerOn
                          ? Colors.blue
                          : Colors.white.withOpacity(0.3),
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

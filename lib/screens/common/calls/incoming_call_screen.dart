import 'package:flutter/material.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String chatId;
  final String callerName;
  final String? callerAvatar;
  final String callerId;
  final bool isVideoCall;

  const IncomingCallScreen({
    super.key,
    required this.chatId,
    required this.callerName,
    this.callerAvatar,
    required this.callerId,
    required this.isVideoCall,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _setupCallEndListener();
  }

  void _setupCallEndListener() {
    final socket = SocketService.instance.socket;
    socket?.on('call:end', (data) {
      final endChatId = data is Map ? data['chatId']?.toString() : null;
      if (endChatId == widget.chatId && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _acceptCall() {
    SocketService.instance.emit('call:accept', {
      'chatId': widget.chatId,
      'toUserId': widget.callerId,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => widget.isVideoCall
            ? VideoCallScreen(
                chatId: widget.chatId,
                userName: widget.callerName,
                userAvatar: widget.callerAvatar,
                otherUserId: widget.callerId,
                isInitiator: false,
              )
            : AudioCallScreen(
                chatId: widget.chatId,
                userName: widget.callerName,
                userAvatar: widget.callerAvatar,
                otherUserId: widget.callerId,
                isInitiator: false,
              ),
      ),
    );
  }

  void _rejectCall() {
    SocketService.instance.emit('call:reject', {
      'chatId': widget.chatId,
      'toUserId': widget.callerId,
    });

    Navigator.pop(context);
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: widget.callerAvatar != null
                    ? NetworkImage(widget.callerAvatar!)
                    : const AssetImage('assets/images/doctor.png') as ImageProvider,
              ),
              
              const SizedBox(height: 30),
              
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              Text(
                widget.isVideoCall ? 'Incoming Video Call...' : 'Incoming Audio Call...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 80),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _rejectCall,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _acceptCall,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isVideoCall ? Icons.videocam : Icons.call,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SocketService.instance.off('call:ended');
    SocketService.instance.off('call:failed');
    super.dispose();
  }
}
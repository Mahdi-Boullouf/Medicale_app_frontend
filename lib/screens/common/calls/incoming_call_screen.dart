import 'package:flutter/material.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';
import 'package:docmobi/services/agora_chat_service.dart';

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
  late Animation<double> _pulseAnimation;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupCallEndListener();
  }

  void _setupCallEndListener() {
    final socket = SocketService.instance.socket;
    if (socket != null) {
      socket.on('call:ended', (data) async {
        debugPrint('📞 Call ended event received: $data');
        if (data['chatId'] == widget.chatId && mounted) {
          //  Log as missed call on receiver side
          try {
            await AgoraChatService.instance.sendCallLog(
              conversationId: widget.callerId,
              callType: widget.isVideoCall ? 'video' : 'audio',
              status: 'missed',
              backendChatId: widget.chatId,
            );
          } catch (e) {
            debugPrint('Failed to log missed call: $e');
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call was cancelled')),
              );
              Navigator.pop(context);
            }
          });
        }
      });

      socket.on('call:failed', (data) {
        debugPrint(' Call failed event received: $data');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text('Call failed: ${data['message']}')),
              // );
              Navigator.pop(context);
            }
          });
        }
      });
    }
  }

  void _acceptCall() async {
    if (_isAccepting) {
      debugPrint('⚠️ Already accepting call');
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    debugPrint('Accepting call...');
    debugPrint('Chat ID: ${widget.chatId}');
    debugPrint(' Caller ID: ${widget.callerId}');
    debugPrint('Is Video: ${widget.isVideoCall}');

    try {
      SocketService.instance.emit('call:accept', {
        'chatId': widget.chatId,
        'fromUserId': widget.callerId,
      });

      debugPrint(' Call accept event sent');

      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to appropriate call screen
      if (!mounted) return;

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
    } catch (e) {
      debugPrint(' Error accepting call: $e');
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept call: $e')));
      }
    }
  }

  void _rejectCall() async {
    debugPrint(' Rejecting call...');
    debugPrint(' Chat ID: ${widget.chatId}');
    debugPrint(' Caller ID: ${widget.callerId}');

    try {
      try {
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.callerId,
          callType: widget.isVideoCall ? 'video' : 'audio',
          status: 'declined',
          backendChatId: widget.chatId,
        );
      } catch (e) {
        debugPrint(' Failed to log declined call: $e');
      }

      SocketService.instance.emit('call:reject', {
        'chatId': widget.chatId,
        'toUserId': widget.callerId,
      });

      debugPrint('Call reject event sent');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(' Error rejecting call: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Caller name
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isVideoCall ? Icons.videocam : Icons.phone,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Incoming ${widget.isVideoCall ? 'Video' : 'Voice'} call',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
            const Spacer(),
            // Pulsing avatar
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 3),
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[800],
                  backgroundImage:
                      widget.callerAvatar != null &&
                          widget.callerAvatar!.isNotEmpty &&
                          widget.callerAvatar != 'file:///' &&
                          (widget.callerAvatar!.startsWith('http://') ||
                              widget.callerAvatar!.startsWith('https://'))
                      ? NetworkImage(widget.callerAvatar!)
                      : const AssetImage('assets/images/doctor1.png')
                            as ImageProvider,
                ),
              ),
            ),
            const Spacer(),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  GestureDetector(
                    onTap: _rejectCall,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Accept button
                  GestureDetector(
                    onTap: _isAccepting ? null : _acceptCall,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: _isAccepting
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              widget.isVideoCall ? Icons.videocam : Icons.phone,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

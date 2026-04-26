import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/call_provider.dart';

class AudioCallScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid;

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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CallProvider()
        ..initCall(
          context: context,
          chatId: chatId,
          userName: userName,
          userAvatar: userAvatar,
          otherUserId: otherUserId,
          isInitiator: isInitiator,
          uuid: uuid,
          isVideoCall: false,
        ),
      child: const _AudioCallScreenBody(),
    );
  }
}

class _AudioCallScreenBody extends StatelessWidget {
  const _AudioCallScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: provider.canPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            provider.endCall();
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
                      backgroundImage: provider.userAvatar != null &&
                              provider.userAvatar!.isNotEmpty
                          ? NetworkImage(provider.userAvatar!)
                          : const AssetImage('assets/images/doctor.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      provider.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      provider.isCallConnected
                          ? provider.callDuration
                          : provider.callStatus,
                      style: TextStyle(
                        color: provider.isCallConnected
                            ? Colors.greenAccent
                            : Colors.white70,
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
                            icon: provider.isMuted ? Icons.mic_off : Icons.mic,
                            label: provider.isMuted ? 'Unmute' : 'Mute',
                            onPressed: provider.toggleMute,
                            backgroundColor: provider.isMuted
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                          _buildControlButton(
                            icon: provider.isSpeakerOn
                                ? Icons.volume_up
                                : Icons.volume_down,
                            label: 'Speaker',
                            onPressed: provider.toggleSpeaker,
                            backgroundColor: provider.isSpeakerOn
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
                      onPressed: provider.endCall,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

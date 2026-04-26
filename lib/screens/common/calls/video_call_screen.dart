import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../providers/call_provider.dart';

class VideoCallScreen extends StatelessWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid;

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
          isVideoCall: true,
        ),
      child: const _VideoCallScreenBody(),
    );
  }
}

class _VideoCallScreenBody extends StatelessWidget {
  const _VideoCallScreenBody();

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
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Remote Video (Full Screen)
                if (provider.remoteUid != null && provider.agoraService.engine != null)
                  Positioned.fill(
                    child: AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: provider.agoraService.engine!,
                        canvas: VideoCanvas(uid: provider.remoteUid),
                        connection: RtcConnection(channelId: provider.chatId),
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
                            backgroundImage: provider.userAvatar != null &&
                                    provider.userAvatar!.isNotEmpty
                                ? NetworkImage(provider.userAvatar!)
                                : const AssetImage('assets/images/doctor1.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            provider.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            provider.callStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          if (provider.isInitializing ||
                              provider.callStatus == 'Calling...' ||
                              provider.callStatus == 'Connecting...')
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Local Video (Small View)
                if (!provider.isVideoOff && provider.agoraService.engine != null)
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
                            rtcEngine: provider.agoraService.engine!,
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
                            backgroundImage: provider.userAvatar != null &&
                                    provider.userAvatar!.isNotEmpty
                                ? NetworkImage(provider.userAvatar!)
                                : const AssetImage('assets/images/doctor1.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                provider.isCallConnected
                                    ? provider.callDuration
                                    : provider.callStatus,
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
                            icon: provider.isMuted ? Icons.mic_off : Icons.mic,
                            label: provider.isMuted ? 'Unmute' : 'Mute',
                            onPressed: provider.toggleMute,
                            color: provider.isMuted ? Colors.red : Colors.white,
                          ),
                          _buildControlButton(
                            icon: provider.isVideoOff
                                ? Icons.videocam_off
                                : Icons.videocam,
                            label: provider.isVideoOff ? 'Cam Off' : 'Cam On',
                            onPressed: provider.toggleVideo,
                            color: provider.isVideoOff ? Colors.red : Colors.white,
                          ),
                          _buildControlButton(
                            icon: Icons.cameraswitch,
                            label: 'Switch',
                            onPressed: provider.switchCamera,
                            color: Colors.white,
                          ),
                          _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End',
                            onPressed: provider.endCall,
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
      },
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
              color: isEndCall ? Colors.red : Colors.white.withValues(alpha: 0.2),
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

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/agora_config.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  static AgoraService get instance => _instance;

  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;

  // Callbacks
  Function(int uid, int elapsed)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function(RtcStats stats)? onLeaveChannel;
  Function(int uid, bool muted)? onUserMuteAudio;
  Function(int uid, bool muted)? onUserMuteVideo;
  Function(ConnectionStateType state, ConnectionChangedReasonType reason)?
  onConnectionStateChanged;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request permissions
      await [Permission.microphone, Permission.camera].request();

      // 2. Create and initialize engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // 3. Set Video Profile (Optimized for High Quality Mobile)
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 960, height: 540), // 540p Quality
          frameRate: 24, // Smoother motion
          bitrate: 1200, // Higher bitrate for clarity
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainQuality,
        ),
      );

      // 4. Set Audio Profile (High Fidelity)
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // 5. Enable Advanced Features
      await _engine!.enableDualStreamMode(enabled: true);
      await _engine!.setParameters(
        '{"che.audio.opensl":true}',
      ); // Low latency audio
      await _engine!.setParameters(
        '{"rtc.noise_suppression":true}',
      ); // AI Noise Suppression

      // 4. Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
              "✅ Local user ${connection.localUid} joined channel: ${connection.channelId}",
            );
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("👋 Remote user $remoteUid joined");
            onUserJoined?.call(remoteUid, elapsed);
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint("🏃 Remote user $remoteUid left channel: $reason");
                onUserOffline?.call(remoteUid, reason);
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("👋 Left channel");
            onLeaveChannel?.call(stats);
          },
          onUserMuteAudio:
              (RtcConnection connection, int remoteUid, bool muted) {
                debugPrint("🔇 Remote user $remoteUid audio muted: $muted");
                onUserMuteAudio?.call(remoteUid, muted);
              },
          onUserMuteVideo:
              (RtcConnection connection, int remoteUid, bool muted) {
                debugPrint("📷 Remote user $remoteUid video muted: $muted");
                onUserMuteVideo?.call(remoteUid, muted);
              },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                debugPrint(
                  "📶 Connection state changed: $state, reason: $reason",
                );
                onConnectionStateChanged?.call(state, reason);
              },
        ),
      );

      // 4. Enable audio/video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      _isInitialized = true;
      debugPrint("✅ Agora Engine Initialized");
    } catch (e) {
      debugPrint("❌ Error initializing Agora: $e");
      rethrow;
    }
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid, // Use 0 for auto-assign if not strict
    bool isVideo = true,
    String? token, // ✅ Dynamic Token
  }) async {
    if (!_isInitialized) await initialize();

    try {
      if (isVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      await _engine!.joinChannel(
        token: token ?? AgoraConfig.token ?? '', // Prioritize dynamic token
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      debugPrint("⏳ Joining channel: $channelName as uid: $uid");
    } catch (e) {
      debugPrint("❌ Error joining channel: $e");
      rethrow;
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> leaveChannel() async {
    try {
      await _engine!.leaveChannel();
      // Don't destroy engine here if we want to reuse it,
      // but usually for a clean state in single call apps, we might want to release.
      // For now, just leaving channel.
    } catch (e) {
      debugPrint("❌ Error leaving channel: $e");
    }
  }

  Future<void> toggleAudio(bool muted) async {
    await _engine!.muteLocalAudioStream(muted);
  }

  Future<void> toggleVideo(bool muted) async {
    await _engine!.muteLocalVideoStream(muted);
  }

  Future<void> switchCamera() async {
    await _engine!.switchCamera();
  }

  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }

  RtcEngine? get engine => _engine;
}

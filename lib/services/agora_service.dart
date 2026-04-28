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
  String? _currentChannel;
  final Set<int> _remoteUids = {};

  bool get isInitialized => _isInitialized;
  String? get currentChannel => _currentChannel;
  Set<int> get remoteUids => _remoteUids;

  // Callbacks
  Function(int uid, int elapsed)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function(RtcStats stats)? onLeaveChannel;
  Function(int uid, bool muted)? onUserMuteAudio;
  Function(int uid, bool muted)? onUserMuteVideo;
  Function(ConnectionStateType state, ConnectionChangedReasonType reason)?
  onConnectionStateChanged;

  /// Initialize the Agora engine ONCE. Reused across all calls.
  /// The engine is a native singleton — releasing and recreating it
  /// in quick succession causes AgoraRtcException(-17).
  Future<void> initialize({
    bool skipPermissions = false,
    bool isVideo = true,
  }) async {
    //  If engine is already initialized and healthy, reuse it
    if (_isInitialized && _engine != null) {
      debugPrint("Agora Engine already initialized — reusing");
      return;
    }

    // Clean up bad state (engine exists but not initialized)
    if (_engine != null) {
      debugPrint(" Engine in bad state — force releasing before re-init");
      try {
        await _engine!.release();
      } catch (_) {}
      _engine = null;
      // Add delay to let native singleton fully release
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _isInitialized = false;

    try {
      // 1. Request permissions (SKIP IF IN BACKGROUND/LOCKED)
      if (!skipPermissions) {
        await [Permission.microphone, Permission.camera].request();
      } else {
        debugPrint(
          " [Agora] Skipping permission request for background initialization",
        );
      }

      // 2. Create and initialize engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // 3. Set Video Profile
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 960, height: 540),
          frameRate: 24,
          bitrate: 1200,
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainQuality,
        ),
      );

      // 4. Set Audio Profile
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // 5. Enable Advanced Features
      await _engine!.enableDualStreamMode(enabled: true);
      await _engine!.setParameters('{"che.audio.opensl":true}');
      await _engine!.setParameters('{"rtc.noise_suppression":true}');

      // 6. Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
              " Local user ${connection.localUid} joined channel: ${connection.channelId}",
            );
            _remoteUids.clear(); // ✅ Clear on fresh join
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint(" Remote user $remoteUid joined");
            _remoteUids.add(remoteUid); // ✅ Track user
            onUserJoined?.call(remoteUid, elapsed);
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint(" Remote user $remoteUid left channel: $reason");
                _remoteUids.remove(remoteUid); // ✅ Untrack user
                onUserOffline?.call(remoteUid, reason);
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("Left channel");
            _remoteUids.clear(); // ✅ Clear on leave
            onLeaveChannel?.call(stats);
          },
          onUserMuteAudio:
              (RtcConnection connection, int remoteUid, bool muted) {
                debugPrint(" Remote user $remoteUid audio muted: $muted");
                onUserMuteAudio?.call(remoteUid, muted);
              },
          onUserMuteVideo:
              (RtcConnection connection, int remoteUid, bool muted) {
                debugPrint(" Remote user $remoteUid video muted: $muted");
                onUserMuteVideo?.call(remoteUid, muted);
              },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                debugPrint(
                  " Connection state changed: $state, reason: $reason",
                );
                onConnectionStateChanged?.call(state, reason);
              },
        ),
      );

      // 7. Enable audio/video — Bug #5 fix: skip camera for audio-only calls
      if (isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      _isInitialized = true;
      debugPrint(" Agora Engine Initialized Successfully");
    } catch (e) {
      debugPrint(" Error initializing Agora: $e");
      _engine = null;
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
    bool isVideo = true,
    String? token,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      if (_currentChannel == channelName) {
        debugPrint(" [Agora] Already in channel: $channelName — skipping join");
        return;
      }

      //  Always leave any existing channel first to prevent error -17
      try {
        await _engine!.leaveChannel();
        debugPrint(" Left previous channel before joining new one");
      } catch (_) {} // Ignore — might not be in a channel

      if (isVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      await _engine!.joinChannel(
        token: token ?? AgoraConfig.token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      _currentChannel = channelName; // ✅ Set current channel
      debugPrint(" Joining channel: $channelName as uid: $uid");
    } catch (e) {
      debugPrint("Error joining channel: $e");
      rethrow;
    }
  }

  /// Join Channel with User Account (String UID support for MongoDB)
  Future<void> joinChannelWithUserAccount({
    required String channelName,
    required String userAccount,
    bool isVideo = true,
    String? token,
  }) async {
    if (!_isInitialized)
      await initialize(skipPermissions: !isVideo, isVideo: isVideo);

    try {
      // ✅ Early exit if already in the channel to prevent redundant joins and Agora -17 errors
      if (_currentChannel == channelName) {
        debugPrint(" [Agora] Already in channel: $channelName — skipping join");
        return;
      }

      // Always leave any existing channel first to prevent error -17
      if (_currentChannel != null && _currentChannel != channelName) {
        try {
          await _engine!.leaveChannel();
          debugPrint(" Left previous channel before joining new one");
        } catch (_) {} // Ignore — might not be in a channel
      }

      if (isVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      await _engine!.joinChannelWithUserAccount(
        token: token ?? AgoraConfig.token,
        channelId: channelName,
        userAccount: userAccount,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      _currentChannel = channelName; // ✅ Set current channel
      debugPrint(
        " Joining channel with User Account: $userAccount in $channelName",
      );
    } catch (e) {
      debugPrint(" Error joining channel with user account: $e");
      rethrow;
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> leaveChannel() async {
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        _currentChannel = null; // ✅ Clear current channel
        debugPrint(" Left Agora channel (engine kept alive for reuse)");
      }
    } catch (e) {
      debugPrint(" Error leaving channel (may not have been in one): $e");
      // If leaving fails badly, force reinit on next call
      if (e.toString().contains('release') ||
          e.toString().contains('destroy')) {
        try {
          await _engine?.release();
        } catch (_) {}
        _engine = null;
        _isInitialized = false;
      }
    }
  }

  Future<void> toggleAudio(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleVideo(bool muted) async {
    await _engine?.muteLocalVideoStream(muted);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Only call on app termination — not between calls
  Future<void> dispose() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
      } catch (_) {}
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }

  RtcEngine? get engine => _engine;
}

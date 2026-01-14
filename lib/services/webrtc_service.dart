import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class WebRTCService {
  final String chatId;
  final bool isVideo;
  final Function(MediaStream) onRemoteStream;
  final Function() onCallEnded;
  
  String? _remoteUserId;
  String? _currentUserId;

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _isRemoteDescriptionSet = false;
  bool _isDisposed = false;

  WebRTCService({
    required this.chatId,
    required this.isVideo,
    required this.onRemoteStream,
    required this.onCallEnded,
  });

  Future<void> initialize() async {
    if (_isDisposed) throw Exception('Service already disposed');
    
    try {
      print('🎥 Initializing WebRTC...');
      print('   • isVideo: $isVideo');
      print('   • chatId: $chatId');
      
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
                'frameRate': {'ideal': 30},
              }
            : false,
      };

      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      print('✅ Got local stream');
      print('   • Audio tracks: ${localStream!.getAudioTracks().length}');
      print('   • Video tracks: ${localStream!.getVideoTracks().length}');

      await _createPeerConnection();
      print('✅ WebRTC initialized');
    } catch (e) {
      print('❌ Error initializing WebRTC: $e');
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    if (_isDisposed) return;
    
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
            'stun:stun3.l.google.com:19302',
            'stun:stun4.l.google.com:19302',
          ]
        },
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(configuration);
    print('✅ Peer connection created');

    // Add local tracks
    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
      print('📤 Added track to peer connection: ${track.kind}');
    });

    // Handle remote tracks
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (_isDisposed) return;
      
      print('🎬 Received remote track: ${event.track.kind}');
      print('   • Track ID: ${event.track.id}');
      print('   • Streams: ${event.streams.length}');
      
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        print('✅ Setting remote stream');
        onRemoteStream(remoteStream!);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_isDisposed || _remoteUserId == null) {
        print('⚠️ Cannot send ICE candidate - disposed or no remote user');
        return;
      }
      
      print('🧊 ICE candidate generated');
      print('   • Candidate: ${candidate.candidate?.substring(0, 50)}...');
      print('   • To User: $_remoteUserId');
      
      SocketService.instance.emit('call:iceCandidate', {
        'chatId': chatId,
        'toUserId': _remoteUserId,
        'fromUserId': _currentUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (_isDisposed) return;
      print('🔗 Connection state: $state');
      
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('✅ Peer connection established!');
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        print('❌ Connection failed/closed/disconnected');
        if (!_isDisposed) onCallEnded();
      }
    };

    // Handle ICE connection state
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('🧊 ICE connection state: $state');
      
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print('✅ ICE connection established!');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('❌ ICE connection failed - may need TURN server');
      }
    };

    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('🧊 ICE gathering state: $state');
    };
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    print('✅ Current user ID set: $_currentUserId');
  }

  Future<void> createOffer(String toUserId) async {
    if (_isDisposed || _peerConnection == null) {
      print('❌ Cannot create offer - disposed or no peer connection');
      return;
    }
    
    _remoteUserId = toUserId;
    print('📤 Creating offer for user: $toUserId');
    
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      
      await _peerConnection!.setLocalDescription(offer);
      
      print('✅ Offer created and local description set');
      print('   • Type: ${offer.type}');
      print('   • SDP length: ${offer.sdp?.length}');

      final emitResult = await SocketService.instance.emit('call:offer', {
        'chatId': chatId,
        'toUserId': toUserId,
        'fromUserId': _currentUserId,
        'isVideo': isVideo,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
      
      print('📤 Offer emit result: $emitResult');
    } catch (e) {
      print('❌ Error creating offer: $e');
      rethrow;
    }
  }

  Future<void> handleOffer(Map<String, dynamic> offerData, String fromUserId) async {
    if (_isDisposed || _peerConnection == null) {
      print('❌ Cannot handle offer - disposed or no peer connection');
      return;
    }
    
    _remoteUserId = fromUserId;
    print('📥 Handling offer from user: $fromUserId');
    print('   • Offer type: ${offerData['type']}');
    
    try {
      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection!.setRemoteDescription(offer);
      _isRemoteDescriptionSet = true;
      print('✅ Remote description set (offer)');

      await _processPendingCandidates();

      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      
      await _peerConnection!.setLocalDescription(answer);
      print('✅ Answer created and local description set');

      final emitResult = await SocketService.instance.emit('call:answer', {
        'chatId': chatId,
        'toUserId': fromUserId,
        'fromUserId': _currentUserId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      
      print('📤 Answer emit result: $emitResult');
    } catch (e) {
      print('❌ Error handling offer: $e');
      rethrow;
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    if (_isDisposed || _peerConnection == null) {
      print('❌ Cannot handle answer - disposed or no peer connection');
      return;
    }
    
    print('📥 Handling answer');
    print('   • Answer type: ${answerData['type']}');
    
    try {
      final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
      await _peerConnection!.setRemoteDescription(answer);
      _isRemoteDescriptionSet = true;
      print('✅ Remote description set (answer)');

      await _processPendingCandidates();
    } catch (e) {
      print('❌ Error handling answer: $e');
      rethrow;
    }
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidateData) async {
    if (_isDisposed) return;
    
    print('📥 Received ICE candidate');
    
    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (_isRemoteDescriptionSet && _peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
        print('✅ ICE candidate added immediately');
      } else {
        _pendingCandidates.add(candidate);
        print('⏳ ICE candidate queued (${_pendingCandidates.length} pending)');
      }
    } catch (e) {
      print('❌ Error adding ICE candidate: $e');
    }
  }

  Future<void> _processPendingCandidates() async {
    if (_isDisposed || _pendingCandidates.isEmpty || _peerConnection == null) return;
    
    print('🔄 Processing ${_pendingCandidates.length} pending ICE candidates');
    
    final candidates = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    
    for (final candidate in candidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('✅ Pending candidate added');
      } catch (e) {
        print('❌ Error adding pending candidate: $e');
      }
    }
    print('✅ All pending candidates processed');
  }

  void toggleAudio() {
    if (_isDisposed) return;
    final audioTrack = localStream?.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      print('🎤 Audio ${audioTrack.enabled ? "enabled" : "muted"}');
    }
  }

  void toggleVideo() {
    if (_isDisposed) return;
    final videoTrack = localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      videoTrack.enabled = !videoTrack.enabled;
      print('📹 Video ${videoTrack.enabled ? "enabled" : "disabled"}');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    
    print('🧹 Disposing WebRTC service');
    
    localStream?.getTracks().forEach((track) {
      track.stop();
      print('⏹️ Stopped track: ${track.kind}');
    });
    
    await localStream?.dispose();
    await remoteStream?.dispose();
    await _peerConnection?.close();
    _peerConnection?.dispose();
    
    _peerConnection = null;
    localStream = null;
    remoteStream = null;
    _pendingCandidates.clear();
    _isRemoteDescriptionSet = false;
    
    print('✅ WebRTC service disposed');
  }
}

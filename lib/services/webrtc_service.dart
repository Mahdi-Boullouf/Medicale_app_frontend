import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCService {
  final IO.Socket socket;
  final String chatId;
  final bool isVideo;
  final Function(MediaStream) onRemoteStream;
  final Function() onCallEnded;
  
  String? _remoteUserId;
  String? _currentUserId; // ✅ Store current user ID

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _isOfferAnswerSet = false;
  bool _isDisposed = false;

  WebRTCService({
    required this.socket,
    required this.chatId,
    required this.isVideo,
    required this.onRemoteStream,
    required this.onCallEnded,
  });

  Future<void> initialize() async {
    if (_isDisposed) {
      throw Exception('Service already disposed');
    }
    
    try {
      print('🎥 Initializing WebRTC...');
      
      // Get user media
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
      print('✅ Got local stream: ${localStream!.id}');

      // Create peer connection
      await _createPeerConnection();
      
      print('✅ WebRTC initialized successfully');
    } catch (e) {
      print('❌ Error initializing WebRTC: $e');
      throw Exception('Failed to initialize WebRTC: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    if (_isDisposed) return;
    
    try {
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
        ],
        'sdpSemantics': 'unified-plan',
        'iceCandidatePoolSize': 10,
      };

      _peerConnection = await createPeerConnection(configuration);
      print('✅ Peer connection created');

      // Add local stream tracks
      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, localStream!);
          print('✅ Added track to peer connection: ${track.kind}');
        });
      }

      // ✅ Listen for remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (_isDisposed) return;
        
        print('🎬 Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          print('✅ Remote stream received: ${remoteStream!.id}');
          
          // ✅ Call the callback immediately
          try {
            onRemoteStream(remoteStream!);
            print('✅ onRemoteStream callback executed');
          } catch (e) {
            print('❌ Error in onRemoteStream callback: $e');
          }
        }
      };

      // ✅ Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (_isDisposed) return;
        
        print('🧊 ICE candidate generated');
        print('📤 Sending ICE to: $_remoteUserId');
        
        socket.emit('call:iceCandidate', {
          'chatId': chatId,
          'toUserId': _remoteUserId,
          'fromUserId': _currentUserId, // ✅ Include sender ID
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
        print('✅ ICE candidate sent');
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (_isDisposed) return;
        
        print('🔗 Connection state: $state');
        
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          print('✅ Peer connection established!');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          print('❌ Connection failed!');
          onCallEnded();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          print('📴 Connection closed');
          if (!_isDisposed) {
            onCallEnded();
          }
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        print('🧊 ICE connection state: $state');
        
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          print('✅ ICE connection established!');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          print('❌ ICE connection failed!');
        }
      };

      _peerConnection!.onSignalingState = (RTCSignalingState state) {
        print('📡 Signaling state: $state');
      };
      
      print('✅ Peer connection setup complete');
    } catch (e) {
      print('❌ Error creating peer connection: $e');
      throw Exception('Failed to create peer connection: $e');
    }
  }

  // ✅ Create offer (caller side)
  Future<void> createOffer(String toUserId) async {
    if (_isDisposed) return;
    
    _remoteUserId = toUserId;
    
    // ✅ Get current user ID from socket service
    try {
      // Extract from socket connection or pass it explicitly
      print('📤 Creating offer for user: $toUserId');
      
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      
      await _peerConnection!.setLocalDescription(offer);
      _isOfferAnswerSet = true;
      print('✅ Local description set (offer)');
      print('📋 Offer SDP type: ${offer.type}');

      socket.emit('call:offer', {
        'chatId': chatId,
        'toUserId': toUserId,
        'fromUserId': _currentUserId, // ✅ Include sender
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
      print('📤 Offer sent to $toUserId');

      // Add pending candidates after a small delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _processPendingCandidates();
      });
    } catch (e) {
      print('❌ Error creating offer: $e');
      throw Exception('Failed to create offer: $e');
    }
  }

  // ✅ Set current user ID (call this before creating offer)
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    print('✅ Current user ID set: $_currentUserId');
  }

  // ✅ Handle offer (receiver side)
  Future<void> handleOffer(Map<String, dynamic> offerData, String fromUserId) async {
    if (_isDisposed) return;
    
    _remoteUserId = fromUserId;
    
    try {
      print('📥 Handling incoming offer from: $fromUserId');
      print('📋 Offer type: ${offerData['type']}');
      
      final offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );
      
      await _peerConnection!.setRemoteDescription(offer);
      _isOfferAnswerSet = true;
      print('✅ Remote description set (offer)');

      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      
      await _peerConnection!.setLocalDescription(answer);
      print('✅ Local description set (answer)');
      print('📋 Answer SDP type: ${answer.type}');

      socket.emit('call:answer', {
        'chatId': chatId,
        'toUserId': fromUserId,
        'fromUserId': _currentUserId, // ✅ Include sender
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      print('📤 Answer sent to $fromUserId');

      // Add pending candidates after a small delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _processPendingCandidates();
      });
    } catch (e) {
      print('❌ Error handling offer: $e');
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    if (_isDisposed) return;
    
    try {
      print('📥 Handling incoming answer');
      print('📋 Answer type: ${answerData['type']}');
      
      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      
      await _peerConnection!.setRemoteDescription(answer);
      _isOfferAnswerSet = true;
      print('✅ Remote description set (answer)');

      // Add pending candidates after a small delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _processPendingCandidates();
      });
    } catch (e) {
      print('❌ Error handling answer: $e');
    }
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidateData) async {
    if (_isDisposed) return;
    
    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (_isOfferAnswerSet && _peerConnection != null) {
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
    if (_isDisposed || _pendingCandidates.isEmpty) return;
    
    print('🔄 Processing ${_pendingCandidates.length} pending ICE candidates');
    
    for (final candidate in _pendingCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('✅ Pending candidate added');
      } catch (e) {
        print('❌ Error adding pending candidate: $e');
      }
    }
    
    _pendingCandidates.clear();
    print('✅ All pending candidates processed');
  }

  void toggleAudio() {
    if (_isDisposed) return;
    
    try {
      final audioTrack = localStream?.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        print('🎤 Audio ${audioTrack.enabled ? "enabled" : "disabled"}');
      }
    } catch (e) {
      print('❌ Error toggling audio: $e');
    }
  }

  void toggleVideo() {
    if (_isDisposed) return;
    
    try {
      final videoTrack = localStream?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        print('📹 Video ${videoTrack.enabled ? "enabled" : "disabled"}');
      }
    } catch (e) {
      print('❌ Error toggling video: $e');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      print('🧹 Disposing WebRTC service');
      
      // Stop all tracks
      localStream?.getTracks().forEach((track) {
        track.stop();
      });
      
      // Dispose streams
      await localStream?.dispose();
      await remoteStream?.dispose();
      
      // Close peer connection
      await _peerConnection?.close();
      _peerConnection?.dispose();
      
      _peerConnection = null;
      localStream = null;
      remoteStream = null;
      _remoteUserId = null;
      _currentUserId = null;
      _pendingCandidates.clear();
      
      print('✅ WebRTC service disposed');
    } catch (e) {
      print('❌ Error disposing WebRTC: $e');
    }
  }
}
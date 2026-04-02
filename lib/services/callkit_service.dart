import 'package:docmobi/services/callkit_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/common/calls/incoming_call_screen.dart';
import '../screens/common/calls/video_call_screen.dart';
import '../screens/common/calls/audio_call_screen.dart';

class CallKitService {
  static GlobalKey<NavigatorState>? navigatorKey;
  static Map<String, dynamic>? pendingCallData;
  static String? _cachedAgoraToken;
  static final Map<String, DateTime> _recentIncomingCallKeys = {};

  static String? consumeCachedAgoraToken() {
    final token = _cachedAgoraToken;
    _cachedAgoraToken = null;
    debugPrint(
      token != null
          ? ' Consumed pre-fetched Agora token'
          : 'No cached Agora token found',
    );
    return token;
  }

  static String _callDedupKey(Map<String, dynamic> data) {
    return data['uuid']?.toString() ??
        data['id']?.toString() ??
        '${data['chatId']}_${data['callerId']}_${data['callerName']}';
  }

  static bool _shouldSuppressIncomingCall(Map<String, dynamic> data) {
    final key = _callDedupKey(data);
    final now = DateTime.now();

    _recentIncomingCallKeys.removeWhere(
      (_, timestamp) => now.difference(timestamp).inMinutes >= 2,
    );

    final seenAt = _recentIncomingCallKeys[key];
    if (seenAt != null && now.difference(seenAt).inSeconds < 45) {
      debugPrint(' [CallKit] Duplicate incoming call suppressed: $key');
      return true;
    }

    _recentIncomingCallKeys[key] = now;
    return false;
  }

  /// Check for active calls upon startup (Cold Start from Call Accept)
  static Future<void> checkActiveCalls() async {
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls is List && activeCalls.isNotEmpty) {
        debugPrint('[STARTUP] Found active call(s): ${activeCalls.length}');
        final firstCall = activeCalls.first;
        final extra = firstCall['extra'];

        if (extra != null) {
          Map<String, dynamic> data = (extra is Map)
              ? Map<String, dynamic>.from(extra)
              : jsonDecode(jsonEncode(extra));

          // TIMESTAMP CHECK: Prevent Ghost Calls
          if (data['timestamp'] != null) {
            final callTime = DateTime.parse(data['timestamp']);
            final diff = DateTime.now().difference(callTime).inMinutes;

            if (diff > 2) {
              debugPrint(' [STARTUP] Found STALE call (Age: $diff min) - Clearing.');
              await FlutterCallkitIncoming.endAllCalls();
              return;
            }
          }

          debugPrint('[STARTUP] Found VALID active call - Navigating to call screen');
          handleCallKitAction({'extra': data}, accept: true);
        }
      }
    } catch (e) {
      debugPrint(' Error checking active calls: $e');
    }
  }

  /// Consume pending call data and navigate directly to call screen
  static bool consumePendingCallData() {
    if (pendingCallData != null && navigatorKey?.currentState != null) {
      debugPrint(' Consuming pending call data — navigating directly to call screen');
      final data = pendingCallData!;
      pendingCallData = null;
      handleCallKitAction({'extra': data}, accept: true);
      return true;
    }
    return false;
  }

  /// Show CallKit Incoming UI
  static Future<void> showCallKitIncoming(Map<String, dynamic> data) async {
    // Login check — not logged in হলে call দেখাবো না
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint(' [CallKit] User not logged in — skipping incoming call UI');
        return;
      }
    } catch (e) {
      debugPrint(' [CallKit] Could not check auth status: $e');
      return;
    }

    try {
      if (_shouldSuppressIncomingCall(data)) return;

      final uuid = data['uuid'] ?? data['id'] ?? const Uuid().v4();
      final String callerName = data['callerName'] ?? 'Unknown';
      final String? rawCallerId = data['callerId']?.toString();
      final String? callerId = rawCallerId?.split('/').first;
      final String callerAvatar = data['callerAvatar'] ?? '';
      final bool isVideo = data['isVideo'] == 'true' || data['isVideo'] == true;

      debugPrint(' [CallKit] Preparing to show call screen');
      debugPrint('   - Caller: $callerName | Video: $isVideo | Chat ID: ${data['chatId']} | Caller ID: $callerId');

      final CallKitParams params = CallKitParams(
        id: uuid,
        nameCaller: callerName,
        appName: 'Docmobi',
        avatar: callerAvatar,
        handle: 'Docmobi Call',
        type: isVideo ? 1 : 0,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed Call',
          callbackText: 'Call back',
        ),
        duration: 30000,
        extra: data,
        headers: <String, dynamic>{'platform': 'flutter'},
        android: AndroidParams(
          isCustomNotification: false,
          isShowLogo: false,
          isShowFullLockedScreen: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: callerAvatar.isNotEmpty ? callerAvatar : '',
          actionColor: '#4CAF50',
          incomingCallNotificationChannelName: 'Incoming Call',
          missedCallNotificationChannelName: 'Missed Call',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
      debugPrint(' [CallKit] Call screen displayed with UUID: $uuid');
    } catch (e) {
      debugPrint(' Error showing CallKit incoming: $e');
    }
  }

  /// Handle CallKit Action (Accept/Decline)
  static void handleCallKitAction(
    Map<String, dynamic> data, {
    required bool accept,
  }) async {
    try {
      if (!ApiService.isLoggedIn) {
        debugPrint(' ApiService not initialized - initializing now...');
        await ApiService.init();
      }

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[CallKit Action] User not logged in — ignoring action');
        await FlutterCallkitIncoming.endAllCalls();
        return;
      }

      Map<String, dynamic> finalData = Map.from(data);
      if (finalData['chatId'] == null && finalData['extra'] != null) {
        if (finalData['extra'] is Map) {
          finalData.addAll(Map<String, dynamic>.from(finalData['extra']));
        } else if (finalData['extra'] is String) {
          try {
            finalData.addAll(jsonDecode(finalData['extra']));
          } catch (e) {
            debugPrint('Failed to parse extra data string: $e');
          }
        }
      }

      final chatId = finalData['chatId'];
      final rawCallerId = finalData['callerId']?.toString();
      final callerId = rawCallerId?.split('/').first;
      final callerName = finalData['callerName'] ?? 'Unknown';
      final isVideo = finalData['isVideo'] == 'true' || finalData['isVideo'] == true;

      debugPrint(' [CallKit Action] ${accept ? 'ACCEPT' : 'DECLINE'}');

      if (accept) {
        if (chatId != null && callerId != null) {
          final normalizedChatId = chatId.toString();

          for (int retry = 0; retry < 2; retry++) {
            try {
              final tokenResponse = await ApiService.getAgoraToken(channelName: normalizedChatId).timeout(const Duration(seconds: 8));
              final fetchedToken = tokenResponse['data']?['token'];
              if (fetchedToken != null) {
                _cachedAgoraToken = fetchedToken;
                debugPrint(' Agora token pre-fetched and cached!');
                break;
              }
            } catch (e) {
              debugPrint(' Token pre-fetch attempt ${retry + 1} failed: $e');
              if (retry == 0) await Future.delayed(const Duration(milliseconds: 500));
            }
          }

          ApiService.acceptCall({
            'chatId': normalizedChatId,
            'fromUserId': callerId,
          }).then((_) => debugPrint(' API: Call accepted signal sent')).catchError((e) => debugPrint('API: Call accept failed: $e'));

          try {
            final connected = await SocketService.instance.ensureConnected().timeout(const Duration(seconds: 5), onTimeout: () => false);
            if (connected) {
              SocketService.instance.emit('call:accept', {
                'chatId': normalizedChatId,
                'fromUserId': callerId,
              });
            }
          } catch (e) {
            debugPrint('Socket connection failed: $e');
          }
        }

        if (navigatorKey?.currentState != null) {
          final pageBuilder = isVideo
              ? (context, animation, secondaryAnimation) => VideoCallScreen(
                    chatId: chatId ?? '',
                    userName: callerName,
                    userAvatar: finalData['callerAvatar'],
                    otherUserId: callerId ?? '',
                    isInitiator: false,
                  )
              : (context, animation, secondaryAnimation) => AudioCallScreen(
                    chatId: chatId ?? '',
                    userName: callerName,
                    userAvatar: finalData['callerAvatar'],
                    otherUserId: callerId ?? '',
                    isInitiator: false,
                  );

          navigatorKey!.currentState?.push(PageRouteBuilder(
            pageBuilder: pageBuilder as Widget Function(BuildContext, Animation<double>, Animation<double>),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ));
        } else {
          debugPrint(' Navigator not ready, storing pending CALL data for direct navigation');
          pendingCallData = finalData;
        }
      } else {
        debugPrint(' Call declined, sending rejection to caller...');
        if (chatId != null && callerId != null) {
          SocketService.instance.emit('call:reject', {'chatId': chatId, 'toUserId': callerId});
        }
        if (finalData['id'] != null) {
          await FlutterCallkitIncoming.endCall(finalData['id'] as String);
        }
      }
    } catch (e) {
      debugPrint(' Error handling CallKit action: $e');
    }
  }
}

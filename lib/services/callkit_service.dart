import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/agora_service.dart';
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

      Map<String, dynamic> finalData = Map<String, dynamic>.from(data);
      if (finalData['extra'] != null) {
        if (finalData['extra'] is Map) {
          finalData.addAll(Map<String, dynamic>.from(finalData['extra']));
        } else if (finalData['extra'] is String) {
          try {
            finalData.addAll(jsonDecode(finalData['extra']));
          } catch (e) {
            debugPrint(' [CallKit] Failed to parse extra data string: $e');
          }
        }
      }

      final chatId = finalData['chatId']?.toString();
      // ✅ Handle both callerId (FCM) and fromUserId (Socket/Old APNs)
      final rawCallerId = (finalData['callerId'] ?? finalData['fromUserId'])?.toString();
      final callerId = rawCallerId?.split('/').first;
      final callerName = finalData['callerName'] ?? 'Unknown';
      final isVideo = finalData['isVideo'] == 'true' || finalData['isVideo'] == true;

      debugPrint(' [CallKit Action] ${accept ? 'ACCEPT' : 'DECLINE'}');
      debugPrint('   - ChatId: $chatId | CallerId: $callerId | Video: $isVideo');

      if (accept) {
        if (chatId != null && callerId != null) {
          final normalizedChatId = chatId.toString();

          // 1. Pre-fetch Agora Token if possible
          String? fetchedToken;
          debugPrint(' [CallKit] Pre-fetching Agora token for channel: $normalizedChatId');
          for (int retry = 0; retry < 2; retry++) {
            try {
              final tokenResponse = await ApiService.getAgoraToken(channelName: normalizedChatId).timeout(const Duration(seconds: 8));
              fetchedToken = tokenResponse['data']?['token'];
              if (fetchedToken != null) {
                _cachedAgoraToken = fetchedToken;
                debugPrint(' [CallKit] Agora token pre-fetched successfully!');
                break;
              }
            } catch (e) {
              debugPrint(' [CallKit] Token pre-fetch attempt ${retry + 1} failed: $e');
              if (retry == 0) await Future.delayed(const Duration(seconds: 1));
            }
          }

          // 2. Signal Accept to Backend
          ApiService.acceptCall({
            'chatId': normalizedChatId,
            'fromUserId': callerId,
          }).then((_) => debugPrint(' [CallKit] API: Call accepted signal sent'))
            .catchError((e) => debugPrint(' [CallKit] API: Call accept failed: $e'));

          // 3. Socket Signal (Best effort)
          try {
            final connected = await SocketService.instance.ensureConnected().timeout(const Duration(seconds: 5), onTimeout: () => false);
            if (connected) {
              SocketService.instance.emit('call:accept', {
                'chatId': normalizedChatId,
                'fromUserId': callerId,
              });
            }
          } catch (e) {
            debugPrint(' [CallKit] Socket connection failed: $e');
          }

          // 4. ✅ BACKGROUND AGORA JOIN (iOS Lock Screen Fix)
          // For Audio calls, join immediately in the background so conversation can start.
          // For Video calls, join as Audio-Only first to establish connection early.
          try {
            final currentUserId = prefs.getString('user_id');
            if (currentUserId != null && currentUserId.isNotEmpty) {
              final agora = AgoraService.instance;
              
              // Skip permissions if we are likely on the lock screen (background)
              final bool isAppForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
              
              debugPrint(' [CallKit] Attempting Background Agora Join (Foreground: $isAppForeground)...');
              
              // Use the fetched token or cached token
              final tokenToUse = fetchedToken ?? _cachedAgoraToken;
              
              if (tokenToUse != null) {
                // Join as Audio-Only if it's an audio call or if we're in the background
                await agora.joinChannelWithUserAccount(
                  channelName: normalizedChatId,
                  userAccount: currentUserId,
                  isVideo: isVideo && isAppForeground, // Only enable camera if in foreground
                  token: tokenToUse,
                );
                debugPrint(' [CallKit] Background Agora join SUCCESSFUL');
              }
            }
          } catch (e) {
            debugPrint(' [CallKit] Background Agora join failed: $e');
          }
        }

        // 4. RETROACTIVE NAVIGATION (iOS Lock Screen & Cold Start Fix)
        // If the navigator isn't ready yet, or the app is still unlocking (iOS),
        // we retry for up to 15 seconds to give the user time to finalize FaceID/Passcode.
        bool navigated = false;
        final int maxAttempts = Platform.isIOS ? 60 : 20; // 60 * 250ms = 15s
        
        for (int i = 0; i < maxAttempts; i++) {
          final currentLifecycle = WidgetsBinding.instance.lifecycleState;
          
          // On iOS, we can sometimes navigate while "inactive" (during transition)
          // But "resumed" is the most stable. We allow BOTH for faster response.
          final bool isReadyForNav = !Platform.isIOS || 
                                   currentLifecycle == AppLifecycleState.resumed ||
                                   currentLifecycle == AppLifecycleState.inactive;
          
          if (navigatorKey?.currentState != null && isReadyForNav) {
            debugPrint(' [CallKit] App state ($currentLifecycle) and Navigator READY! (Attempt ${i + 1})');
            final pageBuilder = isVideo
                ? (context, animation, secondaryAnimation) => VideoCallScreen(
                      chatId: chatId ?? '',
                      userName: callerName,
                      userAvatar: finalData['callerAvatar'],
                      otherUserId: callerId ?? '',
                      isInitiator: false,
                      uuid: finalData['uuid']?.toString() ?? finalData['id']?.toString(),
                    )
                : (context, animation, secondaryAnimation) => AudioCallScreen(
                      chatId: chatId ?? '',
                      userName: callerName,
                      userAvatar: finalData['callerAvatar'],
                      otherUserId: callerId ?? '',
                      isInitiator: false,
                      uuid: finalData['uuid']?.toString() ?? finalData['id']?.toString(),
                    );

            navigatorKey!.currentState?.push(PageRouteBuilder(
              pageBuilder: pageBuilder as Widget Function(BuildContext, Animation<double>, Animation<double>),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
            navigated = true;
            break;
          } else {
            final String reason = (navigatorKey?.currentState == null) ? "Navigator NULL" : "App State $currentLifecycle";
            if (i % 4 == 0) debugPrint(' [CallKit] Waiting to push call screen: $reason... (Attempt ${i + 1})');
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }

        if (!navigated) {
          debugPrint(' [CallKit] ❌ Failed to navigate after ${maxAttempts/2} seconds. Storing in pendingCallData.');
          pendingCallData = finalData;
        }
      } else {
        debugPrint(' [CallKit] Call declined, sending rejection via API (Background Safe)...');
        if (chatId != null && callerId != null) {
          ApiService.rejectCall({
            'chatId': chatId.toString(),
            'toUserId': callerId.toString(),
          }).then((_) => debugPrint(' [CallKit] API: Reject signal sent to caller'))
            .catchError((e) => debugPrint(' [CallKit] API: Reject signal failed: $e'));
          
          // Socket attempt too (if app is in foreground)
          SocketService.instance.emit('call:reject', {
            'chatId': chatId.toString(),
            'toUserId': callerId.toString()
          });
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

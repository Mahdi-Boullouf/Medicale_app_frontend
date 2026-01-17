import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:docmobi/config/agora_config.dart';
import 'package:docmobi/services/api_service.dart';
import 'dart:io';

class AgoraChatService {
  static final AgoraChatService _instance = AgoraChatService._internal();
  static AgoraChatService get instance => _instance;

  AgoraChatService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    ChatOptions options = ChatOptions(
      appKey: AgoraConfig.chatAppKey,
      autoLogin: false,
      enableDNSConfig: true,
    );

    await ChatClient.getInstance.init(options);

    // ✅ CRITICAL: Notify the SDK that the UI is ready to receive callbacks
    await ChatClient.getInstance.startCallback();

    _isInitialized = true;
    debugPrint('✅ Agora Chat SDK Initialized & Callbacks Started');
  }

  bool get isConnected => _isInitialized;

  Future<void> login(String userId, {String? token}) async {
    try {
      if (await ChatClient.getInstance.isLoginBefore()) {
        final currentId = await ChatClient.getInstance.getCurrentUserId();
        if (currentId == userId) {
          debugPrint('✅ Already logged in as $userId');
          return;
        }
        await ChatClient.getInstance.logout();
      }

      String? loginToken = token;
      if (loginToken == null) {
        debugPrint('🔍 Fetching Agora Chat token for login...');
        final response = await ApiService.getAgoraChatToken();
        if (response['success'] == true) {
          loginToken = response['data']?['token'];
        }
      }

      if (loginToken != null && loginToken.isNotEmpty) {
        debugPrint('✅ Logging into Agora with token');
        await ChatClient.getInstance.loginWithToken(userId, loginToken);
      } else {
        // Fallback or error - using userId as password (original insecure way)
        debugPrint('⚠️ No token found, falling back to insecure login');
        await ChatClient.getInstance.login(userId, userId);
      }
      debugPrint('✅ Agora Chat Login Success: $userId');
    } on ChatError catch (e) {
      if (e.code == 200) {
        // ✅ Error 200 means "User already logged in"
        debugPrint('ℹ️ User already logged in (Code 200)');
      } else if (e.code == 204) {
        // ✅ Error 204 means "User does not exist" - Try to register
        debugPrint(
          '⚠️ User $userId does not exist on Agora. Attempting auto-registration...',
        );
        try {
          // Note: createAccount requires password. We use userId as password for simplicity if token is not used.
          // In a production app, this should be handled server-side.
          await ChatClient.getInstance.createAccount(userId, userId);
          debugPrint(
            '✅ Agora Auto-Registration Success for $userId. Retrying login...',
          );
          // Retry login after successful registration
          await login(userId, token: token);
        } on ChatError catch (regError) {
          debugPrint(
            '❌ Agora Auto-Registration Failed: ${regError.description} (Code: ${regError.code})',
          );
        }
      } else {
        debugPrint(
          '❌ Agora Chat Login Failed: ${e.description} (Code: ${e.code})',
        );
      }
    }
  }

  Future<void> logout() async {
    try {
      await ChatClient.getInstance.logout();
      debugPrint('✅ Agora Chat Logout Success');
    } on ChatError catch (e) {
      debugPrint('❌ Agora Chat Logout Failed: ${e.description}');
    }
  }

  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
    ChatType type = ChatType.Chat,
    List<File>? files,
    Map<String, dynamic>? attributes, // ✅ Added attributes support
  }) async {
    try {
      ChatMessage? lastMessage;

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final message = ChatMessage.createImageSendMessage(
            targetId: conversationId,
            filePath: file.path,
            chatType: type,
          );
          if (attributes != null) {
            message.attributes = attributes;
          }

          // Add status listener for better debugging
          ChatClient.getInstance.chatManager.addMessageEvent(
            "SEND_HANDLER_${DateTime.now().millisecondsSinceEpoch}",
            ChatMessageEvent(
              onSuccess: (msgId, msg) => debugPrint("✅ File sent: $msgId"),
              onError: (msgId, msg, err) =>
                  debugPrint("❌ File send failed: ${err.description}"),
            ),
          );

          await ChatClient.getInstance.chatManager.sendMessage(message);
          lastMessage = message;
        }

        if (content.isNotEmpty) {
          final message = ChatMessage.createTxtSendMessage(
            targetId: conversationId,
            content: content,
            chatType: type,
          );
          if (attributes != null) {
            message.attributes = attributes;
          }
          await ChatClient.getInstance.chatManager.sendMessage(message);
          lastMessage = message;
        }
      } else {
        final message = ChatMessage.createTxtSendMessage(
          targetId: conversationId,
          content: content,
          chatType: type,
        );
        if (attributes != null) {
          message.attributes = attributes;
        }

        ChatClient.getInstance.chatManager.addMessageEvent(
          "SEND_HANDLER_${DateTime.now().millisecondsSinceEpoch}",
          ChatMessageEvent(
            onSuccess: (msgId, msg) => debugPrint("✅ Message sent: $msgId"),
            onError: (msgId, msg, err) =>
                debugPrint("❌ Message send failed: ${err.description}"),
          ),
        );

        await ChatClient.getInstance.chatManager.sendMessage(message);
        lastMessage = message;
      }

      return lastMessage;
    } on ChatError catch (e) {
      debugPrint('❌ Send Message Failed: ${e.description}');
      rethrow;
    }
  }

  void addMessageListener(String identifier, ChatEventHandler handler) {
    ChatClient.getInstance.chatManager.addEventHandler(identifier, handler);
  }

  void removeMessageListener(String identifier) {
    ChatClient.getInstance.chatManager.removeEventHandler(identifier);
  }

  Future<List<ChatMessage>> fetchHistoryMessages({
    required String conversationId,
    String? startMsgId,
    int pageSize = 20,
  }) async {
    try {
      final result = await ChatClient.getInstance.chatManager
          .fetchHistoryMessages(
            conversationId: conversationId,
            startMsgId: startMsgId ?? '',
            pageSize: pageSize,
          );
      return result.data;
    } on ChatError catch (e) {
      debugPrint('❌ Fetch History Failed: ${e.description}');
      return [];
    }
  }

  Future<List<ChatMessage>> loadMessagesFromLocal({
    required String conversationId,
    int pageSize = 20,
  }) async {
    try {
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);
      if (conv == null) return [];

      final messages = await conv.loadMessages();
      return messages;
    } on ChatError catch (e) {
      debugPrint('❌ Load Local Messages Failed: ${e.description}');
      return [];
    }
  }

  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final List<ChatConversation> list = await ChatClient
          .getInstance
          .chatManager
          .loadAllConversations();
      return list;
    } on ChatError catch (e) {
      debugPrint('❌ Fetch Conversations Failed: ${e.description}');
      return [];
    }
  }

  Future<ChatMessage?> sendCallLog({
    required String conversationId,
    required String callType, // 'audio' or 'video'
    required String status, // 'missed', 'declined', 'ended', 'cancelled'
    String duration = '',
  }) async {
    final attributes = {
      'type': 'call_log',
      'call_type': callType,
      'status': status,
      'duration': duration,
    };

    String content = '';
    switch (status) {
      case 'missed':
        content = 'Missed ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'declined':
        content = 'Declined ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'cancelled':
        content = 'Cancelled ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'ended':
        // Clean content for UI bubble handling
        content = '${callType == 'video' ? 'Video' : 'Voice'} call ended';
        break;
      default:
        content = '${callType == 'video' ? 'Video' : 'Voice'} call';
    }

    return sendMessage(
      conversationId: conversationId,
      content: content,
      attributes: attributes,
    );
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);
      await conv?.markAllMessagesAsRead();
      debugPrint('✅ Marked all messages as read for $conversationId');
    } catch (e) {
      debugPrint('❌ Mark as Read Failed: $e');
    }
  }

  Future<void> deleteMessages({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);
      if (conv == null) return;

      await conv.deleteMessageByIds(messageIds);

      // ✅ Server-side deletion
      await ChatClient.getInstance.chatManager.deleteRemoteMessagesWithIds(
        conversationId: conversationId,
        type: ChatConversationType.Chat,
        msgIds: messageIds,
      );

      debugPrint(
        '✅ Deleted ${messageIds.length} messages from $conversationId (Local & Server)',
      );
    } catch (e) {
      debugPrint('❌ Delete Messages Failed: $e');
      rethrow;
    }
  }

  Future<void> deleteConversation({
    required String conversationId,
    bool deleteMessages = true,
  }) async {
    try {
      await ChatClient.getInstance.chatManager.deleteConversation(
        conversationId,
        deleteMessages: deleteMessages,
      );

      // ✅ Server-side deletion
      await ChatClient.getInstance.chatManager.deleteRemoteConversation(
        conversationId,
        conversationType: ChatConversationType.Chat,
        isDeleteMessage: deleteMessages,
      );

      debugPrint('✅ Deleted conversation: $conversationId (Local & Server)');
    } catch (e) {
      debugPrint('❌ Delete Conversation Failed: $e');
      rethrow;
    }
  }
}

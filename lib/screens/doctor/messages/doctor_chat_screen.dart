import 'package:docmobi/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/services/api_service.dart';

import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';

// Modular Widgets
import 'package:docmobi/widgets/chat/chat_bubble.dart';
import 'package:docmobi/widgets/chat/call_log_bubble.dart';
import 'package:docmobi/widgets/chat/chat_date_separator.dart';
import 'package:docmobi/widgets/chat/chat_app_bar.dart';
import 'package:docmobi/widgets/chat/chat_input.dart';

class DoctorChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String userRole;
  final String? otherUserId;

  const DoctorChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
    this.otherUserId,
  });

  @override
  State<DoctorChatDetailScreen> createState() => _DoctorChatDetailScreenState();
}

class _DoctorChatDetailScreenState extends State<DoctorChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  List<File> _selectedFiles = [];
  String? _currentUserId;
  String? _currentUserRole;
  String? _currentUserAvatar;
  String? _currentUserName;
  String? _resolvedOtherUserId;
  String? _actualUserAvatar;
  String? _actualUserName;
  bool _isAutoScrollEnabled = true;
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;
  bool _isOtherUserTyping = false;
  Timer? _myTypingTimer;
  Timer? _otherUserTypingTimer;

  @override
  void initState() {
    super.initState();
    _resolvedOtherUserId = widget.otherUserId;
    _actualUserAvatar = widget.userAvatar;
    _actualUserName = widget.userName;
    _loadCurrentUserProfile().then((_) {
      _setupAgoraListeners();
      _loadMessages();
      _ensureAgoraConnection();
      _setupSocketListeners();
      final targetId = _resolvedOtherUserId ?? widget.otherUserId;
      if (targetId != null) {
        AgoraChatService.instance.markAllMessagesAsRead(targetId);

        ApiService.markChatAsRead(chatId: widget.chatId);
      }
    });

    PushNotificationService.currentChatId = widget.chatId;
    PushNotificationService.clearBadge();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        _isAutoScrollEnabled = (maxScroll - currentScroll) < 100;
      }
    });
  }

  Future<void> _ensureAgoraConnection() async {
    // 1. Initialize if needed
    if (!AgoraChatService.instance.isConnected) {
      await AgoraChatService.instance.init();
    }

    // 2. Check if logged in
    final isLoggedIn = await ChatClient.getInstance.isLoginBefore();
    debugPrint(
      ' [Doctor] Agora Login Status: $isLoggedIn | CurrentUser: $_currentUserId',
    );

    if (!isLoggedIn && _currentUserId != null) {
      debugPrint(
        ' [Doctor] Not logged in. Attempting login for $_currentUserId...',
      );
      await AgoraChatService.instance.login(_currentUserId!);
    } else if (isLoggedIn) {
      final currentAgoraUser = await ChatClient.getInstance.getCurrentUserId();
      if (currentAgoraUser != _currentUserId && _currentUserId != null) {
        debugPrint(
          '[Doctor] Agora ID mismatch ($currentAgoraUser vs $_currentUserId). Relogging...',
        );
        await AgoraChatService.instance.logout();
        await AgoraChatService.instance.login(_currentUserId!);
      }
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
          _currentUserRole = profileResult['data']['role']?.toString();
          _currentUserAvatar = profileResult['data']['avatar']?['url']
              ?.toString();
          _currentUserName = profileResult['data']['fullName']?.toString();
          _actualUserName = profileResult['data']['fullName']?.toString();
        });

        debugPrint('Current user profile loaded:');
        debugPrint('   ID: $_currentUserId');
        debugPrint('   Role: $_currentUserRole');
        debugPrint('   Avatar: $_currentUserAvatar');
        debugPrint('   Name: $_currentUserName');
      }
    } catch (e) {
      debugPrint(' Error loading user profile: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = _messages.isEmpty);

    final otherId = _resolvedOtherUserId ?? widget.otherUserId;
    if (otherId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      //  Use local database for initial load (Much faster!)
      final localMessages = await AgoraChatService.instance
          .loadMessagesFromLocal(conversationId: otherId);

      if (mounted) {
        setState(() {
          // Sort newest messages to the top for reverse: true
          localMessages.sort((a, b) => b.serverTime.compareTo(a.serverTime));
          _messages = localMessages
              .map((m) => _convertAgoraMessage(m))
              .toList();
          _isLoading = false;
        });

        // Try to identify other user ID if not set
        if (_resolvedOtherUserId == null && localMessages.isNotEmpty) {
          for (var m in localMessages) {
            if (m.from != _currentUserId) {
              setState(() => _resolvedOtherUserId = m.from);
              break;
            }
          }
        }

        _scrollToBottom();
      }

      // Sync from server in background silently
      AgoraChatService.instance
          .fetchHistoryMessages(conversationId: otherId)
          .then((remoteMessages) {
            if (mounted && remoteMessages.isNotEmpty) {
              setState(() {
                // MERGE instead of replace to preserve real-time messages
                final existingIds = _messages.map((m) => m['_id']).toSet();
                final newMessages = remoteMessages
                    .where((m) => !existingIds.contains(m.msgId))
                    .map((m) => _convertAgoraMessage(m))
                    .toList();

                // Insert new messages at the beginning (newest first)
                _messages.insertAll(0, newMessages);

                // Sort to ensure correct order
                _messages.sort(
                  (a, b) => DateTime.parse(
                    b['createdAt'],
                  ).compareTo(DateTime.parse(a['createdAt'])),
                );
              });
            }
          });
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  Real-time Socket Listeners
  void _setupSocketListeners() {
    if (_currentUserId != null) {
      SocketService.instance.ensureConnected();

      // Listen for typing
      SocketService.instance.on('chat:typing', (data) {
        if (data['chatId'] == widget.chatId && mounted) {
          setState(() => _isOtherUserTyping = true);

          // Auto-hide after 5 seconds if no stop signal
          _otherUserTypingTimer?.cancel();
          _otherUserTypingTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => _isOtherUserTyping = false);
          });
        }
      });

      // Listen for stop typing
      SocketService.instance.on('chat:stopTyping', (data) {
        if (data['chatId'] == widget.chatId && mounted) {
          setState(() => _isOtherUserTyping = false);
          _otherUserTypingTimer?.cancel();
        }
      });
    }
  }

  void _onTextChanged(String value) {
    final otherId = _resolvedOtherUserId ?? widget.otherUserId;
    if (otherId == null) return;

    // Only emit if not already "typing" in the last 2 seconds
    if (_myTypingTimer == null || !_myTypingTimer!.isActive) {
      SocketService.instance.emit('chat:typing', {
        'toUserId': otherId,
        'chatId': widget.chatId,
      });
    }

    _myTypingTimer?.cancel();
    _myTypingTimer = Timer(const Duration(seconds: 3), () {
      SocketService.instance.emit('chat:stopTyping', {
        'toUserId': otherId,
        'chatId': widget.chatId,
      });
    });
  }

  //  Multi-select Delete Helper
  void _toggleSelection(String msgId) {
    setState(() {
      if (_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.remove(msgId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(msgId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessages),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteMessagesConfirm(_selectedMessageIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.deleteLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final idsToDelete = _selectedMessageIds.toList();
        await AgoraChatService.instance.deleteMessages(
          conversationId: widget.chatId,
          messageIds: idsToDelete,
        );

        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => idsToDelete.contains(m['_id']));
            _cancelSelection();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.messagesDeleted),
            ),
          );
        }
      } catch (e) {
        debugPrint(' Failed to delete messages: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToDelete(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    // With reverse: true, "bottom" is offset 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _isAutoScrollEnabled) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, dynamic> _convertAgoraMessage(ChatMessage message) {
    String content = '';
    List<Map<String, dynamic>> fileUrl = [];

    if (message.body is ChatTextMessageBody) {
      content = (message.body as ChatTextMessageBody).content;
    } else if (message.body is ChatImageMessageBody) {
      final body = message.body as ChatImageMessageBody;
      fileUrl.add({
        'url': body.remotePath ?? body.localPath,
        'name': body.displayName ?? 'image.jpg',
      });
    } else if (message.body is ChatFileMessageBody) {
      final body = message.body as ChatFileMessageBody;
      fileUrl.add({
        'url': body.remotePath ?? body.localPath,
        'name': body.displayName ?? 'file',
      });
    }

    final bool isMe = message.from == _currentUserId;

    return {
      '_id': message.msgId,
      'content': content.isEmpty ? ' ' : content,
      'sender': {
        '_id': message.from,
        'fullName': isMe
            ? (_currentUserName ?? AppLocalizations.of(context)!.meLabel)
            : (_actualUserName ?? widget.userName),
        'avatar': {'url': isMe ? _currentUserAvatar : _actualUserAvatar},
      },
      'fileUrl': fileUrl,
      ...message.attributes ?? {},
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        message.serverTime,
      ).toIso8601String(),
    };
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();

    debugPrint(
      '[Doctor] Attempting to send message. Content length: ${content.length}',
    );

    if (content.isEmpty && _selectedFiles.isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final otherId = _resolvedOtherUserId ?? widget.otherUserId;
      if (otherId == null) throw Exception('Recipient ID missing');

      debugPrint('✉️ [Doctor] Sending to ID: $otherId');
      debugPrint('   - Me (UID): $_currentUserId');

      final sentMessage = await AgoraChatService.instance.sendMessage(
        conversationId: otherId,
        content: content,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        backendChatId: widget.chatId, // Trigger backend notification
      );

      debugPrint(
        '[Doctor] Message returned from SDK: ${sentMessage?.msgId ?? "NULL"}',
      );

      if (sentMessage != null && mounted) {
        _controller.clear();
        setState(() {
          _selectedFiles = [];
          _isAutoScrollEnabled = true;
          // Optimistic update: Add message to TOP for reverse: true
          _messages.insert(0, _convertAgoraMessage(sentMessage));
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint(' [Doctor] Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _initiateCall({required bool isVideo}) async {
    final targetUserId = _resolvedOtherUserId ?? widget.otherUserId;

    if (targetUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotStartCallNoId),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      debugPrint(
        '${isVideo ? "📹" : "🎤"} Starting ${isVideo ? "video" : "audio"} call...',
      );
      debugPrint(' Current user: $_currentUserId');
      debugPrint(' Other user: $targetUserId');
      debugPrint(' Chat ID: ${widget.chatId}');

      //  Use API instead of direct socket emission
      final socketService = SocketService.instance;
      if (!socketService.isConnected) {
        debugPrint(' Socket not connected, attempting to connect...');
        if (_currentUserId != null) {
          await socketService.connect(_currentUserId!);
          // Wait a bit for connection to stabilize
          await Future.delayed(const Duration(seconds: 1));
        }

        if (!socketService.isConnected) {
          throw Exception('Socket connection failed');
        }
      }

      debugPrint(' Socket connected, initiating call via API...');

      // Use API instead of direct socket emission
      final result = await ApiService.initiateCall(
        chatId: widget.chatId,
        receiverId: targetUserId,
        isVideo: isVideo,
      );

      if (result['success'] == true) {
        debugPrint(' Call initiated successfully');

        if (mounted) {
          final String stableChatId =
              result['data']?['chatId']?.toString() ?? widget.chatId;
          final String? callUuid = result['data']?['uuid']?.toString();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isVideo
                  ? VideoCallScreen(
                      chatId: stableChatId,
                      userName: widget.userName,
                      userAvatar: _actualUserAvatar ?? widget.userAvatar,
                      otherUserId: targetUserId,
                      isInitiator: true,
                      uuid: callUuid,
                    )
                  : AudioCallScreen(
                      chatId: stableChatId,
                      userName: widget.userName,
                      userAvatar: _actualUserAvatar ?? widget.userAvatar,
                      otherUserId: targetUserId,
                      isInitiator: true,
                      uuid: callUuid,
                    ),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to initiate call');
      }
    } catch (e) {
      debugPrint(' Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToStartCall(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: ChatAppBar(
        userName: _actualUserName ?? widget.userName,
        userAvatar: _actualUserAvatar ?? widget.userAvatar,
        placeholderAsset: 'assets/images/doctor1.png',
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedMessageIds.length,
        onCancelSelection: () => setState(() {
          _selectedMessageIds.clear();
          _isSelectionMode = false;
        }),
        onDeleteSelected: _deleteSelectedMessages,
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.blue),
            onPressed: () => _initiateCall(isVideo: true),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.blue),
            onPressed: () => _initiateCall(isVideo: false),
          ),
        ],
        // isOnline removed
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noMessagesYet,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.startConversationWith(widget.userName),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) {
                      final currentMsgDate =
                          _messages[index]['createdAt'] as String;
                      final previousMsgDate = (index + 1 < _messages.length)
                          ? _messages[index + 1]['createdAt'] as String
                          : null;

                      // For reverse: true, we check if the message "above" (next index) is a different day
                      if (previousMsgDate != null &&
                          !_isSameDay(currentMsgDate, previousMsgDate)) {
                        return ChatDateSeparator(timestamp: currentMsgDate);
                      }
                      return const SizedBox.shrink();
                    },
                    itemBuilder: (context, index) {
                      // For the very last message in the list (oldest), show date separator
                      if (index == _messages.length - 1) {
                        return Column(
                          children: [
                            ChatDateSeparator(
                              timestamp: _messages[index]['createdAt'],
                            ),
                            _buildMessageItem(_messages[index]),
                          ],
                        );
                      }
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
          ),

          if (_isOtherUserTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${widget.userName} is typing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ChatInput(
            controller: _controller,
            selectedFiles: _selectedFiles,
            isSending: _isSending,
            onPickImage: _pickImage,
            onRemoveFile: _removeFile,
            onSendMessage: _sendMessage,
            onChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }

  void _setupAgoraListeners() {
    final otherId = _resolvedOtherUserId ?? widget.otherUserId;
    debugPrint(' [DoctorChat] Setting up Agora listeners. Target: $otherId');

    AgoraChatService.instance.addMessageListener(
      'doctor_chat_${widget.chatId}',
      ChatEventHandler(
        onMessagesReceived: (messages) {
          final currentCheckId = _resolvedOtherUserId ?? widget.otherUserId;
          List<dynamic> incomingFormatted = [];

          for (var msg in messages) {
            debugPrint(
              ' [DoctorChat] Received message SDK: ID=${msg.msgId}, From=${msg.from}, Conv=${msg.conversationId}',
            );

            if (msg.conversationId == currentCheckId ||
                msg.from == currentCheckId) {
              debugPrint(' Match found for this chat');

              // Prevent duplicates
              final bool alreadyExists = _messages.any(
                (m) => m['_id'] == msg.msgId,
              );
              if (!alreadyExists) {
                incomingFormatted.add(_convertAgoraMessage(msg));
              }
            }
          }

          if (incomingFormatted.isNotEmpty && mounted) {
            setState(() {
              //  Check for duplicates BEFORE insertion (more efficient)
              final existingIds = _messages.map((m) => m['_id']).toSet();

              for (var msg in incomingFormatted) {
                if (!existingIds.contains(msg['_id'])) {
                  _messages.insert(0, msg);
                  existingIds.add(msg['_id']);
                }
              }

              if (incomingFormatted.length > 1) {
                _messages.sort(
                  (a, b) => DateTime.parse(
                    b['createdAt'],
                  ).compareTo(DateTime.parse(a['createdAt'])),
                );
              }
            });

            _scrollToBottom();

            if (currentCheckId != null) {
              AgoraChatService.instance.markAllMessagesAsRead(
                currentCheckId,
              ); // Clear unread badge live

              //  Sync with backend
              ApiService.markChatAsRead(chatId: widget.chatId);
            }
          }
        },
      ),
    );
    debugPrint(
      ' Agora Chat handlers attached for ID: doctor_chat_${widget.chatId}',
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    if (message['type'] == 'call_log') {
      final String msgId = message['_id']?.toString() ?? '';
      return CallLogBubble(
        message: message,
        isSelected: _selectedMessageIds.contains(msgId),
        onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
        onLongPress: () => _toggleSelection(msgId),
      );
    }

    final String msgId = message['_id']?.toString() ?? '';
    final String senderId = message['sender']?['_id']?.toString() ?? '';
    final bool isMe = _currentUserId != null && senderId == _currentUserId;

    return ChatBubble(
      message: message,
      isMe: isMe,
      isSelected: _selectedMessageIds.contains(msgId),
      currentUserAvatar: _currentUserAvatar,
      otherUserAvatar: _actualUserAvatar,
      otherUserPlaceholder: 'assets/images/doctor1.png',
      onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
      onLongPress: () => _toggleSelection(msgId),
      formatTime: _formatTime,
    );
  }

  @override
  void dispose() {
    _myTypingTimer?.cancel();
    _otherUserTypingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    SocketService.instance.off('chat:typing');
    AgoraChatService.instance.removeMessageListener(
      'doctor_chat_${widget.chatId}',
    );

    //  Leave chat room
    if (_currentUserId != null) {
      SocketService.instance.emit('chat:leave', {
        'chatId': widget.chatId,
        'userId': _currentUserId,
      });
    }
    SocketService.instance.off('user:online');
    SocketService.instance.off('user:offline');

    //  Clear active chat
    if (PushNotificationService.currentChatId == widget.chatId) {
      PushNotificationService.currentChatId = null;
    }

    super.dispose();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  bool _isSameDay(String? ts1, String? ts2) {
    if (ts1 == null || ts2 == null) return false;
    try {
      final d1 = DateTime.parse(ts1).toLocal();
      final d2 = DateTime.parse(ts2).toLocal();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (e) {
      return false;
    }
  }
}

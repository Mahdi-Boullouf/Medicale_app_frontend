import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/screens/doctor/messages/doctor_chat_screen.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class DoctorMessagesListScreen extends StatefulWidget {
  final String? initialDoctorId;

  const DoctorMessagesListScreen({super.key, this.initialDoctorId});

  @override
  State<DoctorMessagesListScreen> createState() =>
      _DoctorMessagesListScreenState();
}

class _DoctorMessagesListScreenState extends State<DoctorMessagesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allChats = [];
  bool isLoading = true;
  String? currentUserId;
  final Set<String> _selectedConversationIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ Use post-frame callback to ensure safe async initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    await _loadCurrentUserId();
    if (currentUserId != null) {
      await _ensureAgoraConnection(); // ✅ Await connection before loading
      _setupAgoraListener();
      _loadChats();

      if (widget.initialDoctorId != null) {
        _createChatWithDoctor(widget.initialDoctorId!);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _ensureAgoraConnection() async {
    // 1. Initialize if needed
    if (!AgoraChatService.instance.isConnected) {
      await AgoraChatService.instance.init();
    }

    // 2. Login Check
    try {
      final isLoggedIn = await ChatClient.getInstance.isLoginBefore();
      if (!isLoggedIn && currentUserId != null) {
        debugPrint('🔄 DoctorListScreen: Logging in $currentUserId...');
        await AgoraChatService.instance.login(currentUserId!);
      }
    } catch (e) {
      debugPrint('❌ DoctorListScreen: Agora Auth Check Failed: $e');
    }
  }

  // ✅ Setup Agora listener for real-time updates
  void _setupAgoraListener() {
    AgoraChatService.instance.addMessageListener(
      'doctor_chat_list_refresher',
      ChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('📨 Agora message received in doctor list - refreshing');
          _loadChatsQuietly(); // Reload chats when new message arrives
        },
      ),
    );
  }

  // ✅ Silent reload (no loading indicator)
  Future<void> _loadChatsQuietly() async {
    await _loadChats(quiet: true);
  }

  Future<void> _loadChats({bool quiet = false}) async {
    if (!quiet) setState(() => isLoading = true);

    try {
      // 1. Fetch conversations from Agora
      final List<ChatConversation> conversations = await AgoraChatService
          .instance
          .fetchConversations();

      // 2. Pre-fetch details for sorting
      List<Map<String, dynamic>> tempChats = [];

      for (var conv in conversations) {
        if (conv.id.isEmpty) continue; // ✅ 'id' instead of 'conversationId'

        final lastMsg = await conv.latestMessage(); // ✅ await the method
        if (lastMsg == null) continue;

        tempChats.add({
          'conv': conv,
          'lastMsg': lastMsg,
          'time': lastMsg.serverTime,
        });
      }

      // Sort by time descending
      tempChats.sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));

      List<Map<String, dynamic>> formattedChats = [];

      for (var item in tempChats) {
        final conv = item['conv'] as ChatConversation;
        final lastMsg = item['lastMsg'] as ChatMessage;
        final conversationId = conv.id;

        // 3. Resolve user details from API
        String userName = 'User';
        String? avatarUrl;
        String role = 'patient'; // Default to patient for doctor view

        try {
          // Resolve backend chatId and user profile
          final result = await ApiService.createOrGetChat(userId: conversationId);
          if (result['success'] == true) {
            final chatData = result['data'];
            final backendChatId = chatData['_id']?.toString();
            
            final participants = chatData['participants'] as List;
            final otherUser = participants.firstWhere(
              (p) => p['_id'] != currentUserId,
              orElse: () => participants[0],
            );
            
            userName = otherUser['fullName'] ?? 'User';
            avatarUrl = otherUser['avatar']?['url'];
            role = otherUser['role'] ?? 'patient';
            
            // Format for UI
            String content = '';
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              if (lastMsg.attributes?['type'] == 'call_log') {
                final isVideo = lastMsg.attributes?['call_type'] == 'video';
                content = isVideo
                    ? (l10n?.videoCall ?? 'Video Call')
                    : (l10n?.voiceCall ?? 'Voice Call');
              } else if (lastMsg.body.type == MessageType.TXT) {
                content = (lastMsg.body as ChatTextMessageBody).content;
              } else if (lastMsg.body.type == MessageType.IMAGE) {
                content = l10n?.imageLabel ?? '[Image]';
              } else if (lastMsg.body.type == MessageType.FILE) {
                content = l10n?.fileLabel ?? '[File]';
              } else {
                content = l10n?.messageLabel ?? '[Message]';
              }
            }

            // ✅ Use the true backend chatId instead of conversationId (UserID)
            formattedChats.add({
              '_id': backendChatId ?? conversationId,
              'actualUserId': conversationId, // Keep for Agora
              'participants': chatData['participants'],
              'lastMessage': {
                'content': content,
                'createdAt': DateTime.fromMillisecondsSinceEpoch(
                  lastMsg.serverTime,
                ).toIso8601String(),
              },
              'unreadCount': await conv.unreadCount(),
              'updatedAt': DateTime.fromMillisecondsSinceEpoch(
                lastMsg.serverTime,
              ).toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('⚠️ Could not resolve chat/user $conversationId: $e');
        }
      }

      if (mounted) {
        setState(() {
          allChats = formattedChats;
          isLoading = false;
        });
        debugPrint('✅ Loaded ${allChats.length} conversations from Agora');
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ Multi-select Delete Helper
  void _toggleSelection(String convId) {
    setState(() {
      if (_selectedConversationIds.contains(convId)) {
        _selectedConversationIds.remove(convId);
        if (_selectedConversationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversationIds.add(convId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedConversationIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteChats),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteConversationsConfirm(_selectedConversationIds.length),
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
        final idsToDelete = _selectedConversationIds.toList();
        for (var id in idsToDelete) {
          await AgoraChatService.instance.deleteConversation(
            conversationId: id,
            deleteMessages: true,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.conversationsDeleted),
            ),
          );
          _cancelSelection();
          _loadChats(); // Reload list
        }
      } catch (e) {
        debugPrint('❌ Failed to delete conversations: $e');
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

  Future<void> _loadCurrentUserId() async {
    try {
      final result = await ApiService.getUserProfile();
      if (result['success'] == true) {
        setState(() {
          currentUserId = result['data']['_id']?.toString();
        });
        await _ensureAgoraConnection(); // ✅ Ensure connection
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _createChatWithDoctor(String doctorId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ApiService.createOrGetChat(userId: doctorId);
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        final chatData = result['data'];
        final chatId = chatData['_id']?.toString();

        if (chatId != null && mounted) {
          final participants = chatData['participants'] as List;
          final otherUser = participants.firstWhere(
            (p) => p['_id'] != currentUserId,
            orElse: () => participants[0],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorChatDetailScreen(
                chatId: chatId,
                userName:
                    otherUser['fullName'] ??
                    AppLocalizations.of(context)!.doctorLabel,
                userAvatar: otherUser['avatar']?['url'],
                userRole: otherUser['role'] ?? 'doctor',
                otherUserId: otherUser['_id'],
              ),
            ),
          ).then((_) {
            if (mounted) _loadChats();
          });

          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  List<Map<String, dynamic>> get uniqueChats {
    return allChats;
  }

  List<Map<String, dynamic>> get doctorChats {
    return uniqueChats.where((chat) {
      final participants = chat['participants'] as List? ?? [];
      return participants.any(
        (p) => p['_id'] != currentUserId && p['role'] == 'doctor',
      );
    }).toList();
  }

  List<Map<String, dynamic>> get patientChats {
    return uniqueChats.where((chat) {
      final participants = chat['participants'] as List? ?? [];
      return participants.any(
        (p) => p['_id'] != currentUserId && p['role'] == 'patient',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: _cancelSelection,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorMainNavigation(),
                    ),
                    (route) => false,
                  );
                },
              ),
        title: Text(
          _isSelectionMode
              ? "${_selectedConversationIds.length} selected"
              : AppLocalizations.of(context)!.messagesLabel,
          style: const TextStyle(
            color: Color(0xFF1B2C49),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteSelectedConversations,
                ),
                const SizedBox(width: 10),
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1664CD),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1664CD),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.allLabel),
            Tab(text: AppLocalizations.of(context)!.doctorsLabel),
            Tab(text: AppLocalizations.of(context)!.patientsLabel),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(uniqueChats),
                _buildChatList(doctorChats),
                _buildChatList(patientChats),
              ],
            ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMessagesYet,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return _buildChatCard(chats[index]);
        },
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];
    // ✅ Robust search for other participant to avoid TypeError
    Map<String, dynamic>? otherUser;
    for (var p in participants) {
      if (p is Map && p['_id'] != currentUserId) {
        otherUser = Map<String, dynamic>.from(p);
        break;
      }
    }

    if (otherUser == null && participants.isNotEmpty) {
      otherUser = Map<String, dynamic>.from(participants[0]);
    }

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final String userName =
        otherUser['fullName'] ?? AppLocalizations.of(context)!.unknown;
    final String? userAvatar = otherUser['avatar']?['url'];
    final String userRole = otherUser['role'] ?? 'user';
    final String lastMessageText =
        chat['lastMessage']?['content'] ??
        AppLocalizations.of(context)!.noMessagesYet;
    final int unreadCount = chat['unreadCount'] ?? 0;

    final String? lastMessageTime = chat['lastMessage']?['createdAt'];
    final String timeText = lastMessageTime != null
        ? _formatTime(DateTime.parse(lastMessageTime))
        : '';

    final String backendId = chat['_id']?.toString() ?? '';
    final String actualUserId = chat['actualUserId']?.toString() ?? backendId;
    final bool isSelected = _selectedConversationIds.contains(backendId);

    return InkWell(
      onTap: _isSelectionMode
          ? () => _toggleSelection(backendId)
          : () async {
              // ✅ Mark as read immediately (optimistic UI update)
              if (unreadCount > 0) {
                setState(() {
                  chat['unreadCount'] = 0;
                });

                // Mark all messages as read in both Agora and backend
                try {
                  // Agora SDK - MUST use UserID
                  await AgoraChatService.instance.markAllMessagesAsRead(actualUserId);
                  debugPrint('✅ Marked conversation $actualUserId as read in Agora');

                  // Backend API - MUST use ChatID
                  await ApiService.markChatAsRead(chatId: backendId);
                  debugPrint(
                    '✅ Marked conversation $backendId as read in backend',
                  );
                } catch (e) {
                  debugPrint('⚠️ Failed to mark as read: $e');
                }
              }

              // Navigate to chat screen
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorChatDetailScreen(
                    chatId: backendId,
                    userName: userName,
                    userAvatar: userAvatar,
                    userRole: userRole,
                    otherUserId: actualUserId,
                  ),
                ),
              ).then((_) {
                 if (mounted) _loadChatsQuietly();
              });

              // ✅ Don't reload chats here - we've also optimistically updated the UI
              // but reloading ensures we catch any changes from the chat screen (like reads)
            },
      onLongPress: () => _toggleSelection(backendId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blue.shade300)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  userAvatar != null &&
                      userAvatar.isNotEmpty &&
                      userAvatar != 'file:///' &&
                      (userAvatar.startsWith('http://') ||
                          userAvatar.startsWith('https://'))
                  ? NetworkImage(userAvatar)
                  : const AssetImage('assets/images/doctor.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2C49),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageText,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? const Color(0xFF1B2C49)
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1664CD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    AgoraChatService.instance.removeMessageListener(
      'doctor_chat_list_refresher',
    );
    super.dispose();
  }
}

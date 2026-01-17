import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/messages/patient_chat_screen.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'dart:async';

class PatientMessagesListScreen extends StatefulWidget {
  const PatientMessagesListScreen({super.key});

  @override
  State<PatientMessagesListScreen> createState() =>
      _PatientMessagesListScreenState();
}

class _PatientMessagesListScreenState extends State<PatientMessagesListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;
  Timer? _autoRefreshTimer;
  Set<String> _selectedConversationIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadChats();
    _startAutoRefresh(); // ✅ Auto-refresh every 3 seconds
    _setupAgoraListener(); // ✅ Listen to Agora messages
  }

  // ✅ Setup Agora listener for real-time updates
  void _setupAgoraListener() {
    AgoraChatService.instance.addMessageListener(
      'patient_chat_list_refresher',
      ChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('📨 Agora message received in list - refreshing');
          _loadChatsQuietly(); // Reload chats when new message arrives
        },
      ),
    );
  }

  // ✅ Start auto-refresh timer
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadChatsQuietly(); // Silent reload without loading indicator
      }
    });
  }

  // ✅ Silent reload (no loading indicator)
  Future<void> _loadChatsQuietly() async {
    await _loadChats(quiet: true);
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
        });
        await _ensureAgoraConnection(); // ✅ Ensure connection
      }
    } catch (e) {
      debugPrint('❌ Error loading current user ID: $e');
    }
  }

  Future<void> _ensureAgoraConnection() async {
    // 1. Initialize
    if (!AgoraChatService.instance.isConnected) {
      await AgoraChatService.instance.init();
    }
    // 2. Login Check
    try {
      final isLoggedIn = await ChatClient.getInstance.isLoginBefore();
      if (!isLoggedIn && _currentUserId != null) {
        debugPrint(
          '🔄 ListScreen: Not logged in. logging in $_currentUserId...',
        );
        await AgoraChatService.instance.login(_currentUserId!);
      }
    } catch (e) {
      debugPrint('❌ ListScreen: Agora Auth Check Failed: $e');
    }
  }

  Future<void> _loadChats({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('🔍 Loading patient chats from Agora SDK...');
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
        String fullName = 'Doctor';
        String? avatarUrl;

        try {
          final userProfile = await ApiService.getUserProfile(
            userId: conversationId,
          );
          if (userProfile['success'] == true) {
            fullName = userProfile['data']['fullName'] ?? 'Doctor';
            avatarUrl = userProfile['data']['avatar']?['url'];
          }
        } catch (e) {
          debugPrint('⚠️ Could not resolve user $conversationId: $e');
        }

        // 4. Format for UI
        String content = '';
        if (lastMsg.attributes?['type'] == 'call_log') {
          final isVideo = lastMsg.attributes?['call_type'] == 'video';
          content = isVideo ? 'Video Call' : 'Voice Call';
        } else if (lastMsg.body.type == MessageType.TXT) {
          content = (lastMsg.body as ChatTextMessageBody).content;
        } else if (lastMsg.body.type == MessageType.IMAGE) {
          content = '[Image]';
        } else if (lastMsg.body.type == MessageType.FILE) {
          content = '[File]';
        } else {
          content = '[Message]';
        }

        formattedChats.add({
          '_id': conversationId,
          'participants': [
            {
              'role': 'doctor',
              '_id': conversationId,
              'fullName': fullName,
              'avatar': {'url': avatarUrl},
            },
          ],
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

      if (mounted) {
        setState(() {
          _chats = formattedChats;
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_chats.length} conversations from Agora');
      }
    } catch (e) {
      debugPrint('❌ Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('Delete Chats'),
        content: Text(
          'Are you sure you want to delete ${_selectedConversationIds.length} conversations? This will remove all messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            const SnackBar(content: Text('Conversations deleted')),
          );
          _cancelSelection();
          _loadChats(); // Reload list
        }
      } catch (e) {
        debugPrint('❌ Failed to delete conversations: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _goBackToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PatientMainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToHome();
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 246),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _cancelSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _goBackToHome,
                ),
          title: Text(
            _isSelectionMode
                ? "${_selectedConversationIds.length} selected"
                : "Messages",
            style: const TextStyle(
              color: Colors.black,
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
        ),
        body: RefreshIndicator(
          onRefresh: _loadChats,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
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
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadChats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(_chats[index]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];

    // ✅ Robust search for doctor participant to avoid TypeError
    Map<String, dynamic>? doctor;
    for (var p in participants) {
      if (p is Map && p['role'] == 'doctor') {
        doctor = Map<String, dynamic>.from(p);
        break;
      }
    }

    if (doctor == null) {
      return const SizedBox.shrink();
    }

    final String doctorName = doctor['fullName']?.toString() ?? 'Doctor';
    final String? doctorAvatar = doctor['avatar']?['url']?.toString();
    final String doctorId = doctor['_id']?.toString() ?? '';

    final lastMessage = chat['lastMessage'];
    final String messageText = lastMessage != null
        ? (lastMessage['content']?.toString() ?? 'Start conversation')
        : 'Start conversation';

    // ✅ Get unread count
    final int unreadCount = chat['unreadCount'] ?? 0;

    final DateTime? updatedAt = chat['updatedAt'] != null
        ? DateTime.tryParse(chat['updatedAt'].toString())
        : null;
    final String timeText = updatedAt != null ? _formatTime(updatedAt) : '';

    final String convId = chat['_id']?.toString() ?? '';
    final bool isSelected = _selectedConversationIds.contains(convId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleSelection(convId)
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chat['_id'].toString(),
                      doctorName: doctorName,
                      doctorAvatar: doctorAvatar,
                      doctorId: doctorId,
                    ),
                  ),
                ).then((_) {
                  _loadChats();
                });
              },
        onLongPress: () => _toggleSelection(convId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.blue.shade300)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    doctorAvatar != null &&
                        doctorAvatar.isNotEmpty &&
                        doctorAvatar != 'file:///' &&
                        (doctorAvatar.startsWith('http://') ||
                            doctorAvatar.startsWith('https://'))
                    ? Image.network(
                        doctorAvatar,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              "assets/images/doctor1.png",
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        "assets/images/doctor1.png",
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Dr.',
                            style: TextStyle(
                              color: Color(0xFF1E61D4),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ✅ Added unread count display
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? const Color(0xFF1B2C49)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // ✅ Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
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
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // ✅ Cancel timer
    AgoraChatService.instance.removeMessageListener(
      'patient_chat_list_refresher',
    );
    super.dispose();
  }
}

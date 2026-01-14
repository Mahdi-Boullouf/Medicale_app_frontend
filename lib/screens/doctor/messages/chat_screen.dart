import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';
import 'package:docmobi/screens/common/calls/incoming_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

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
  String? _otherUserRole;
  String? _actualUserAvatar;
  String? _actualUserName;
  
  Timer? _refreshTimer;
  Set<String> _messageIds = {};
  bool _isAutoScrollEnabled = true;

  // ✅ FIXED: Always show both audio and video icons
  bool get _shouldShowCallIcons => true;

  @override
  void initState() {
    super.initState();
    _resolvedOtherUserId = widget.otherUserId;
    _otherUserRole = widget.userRole;
    _actualUserAvatar = widget.userAvatar;
    _actualUserName = widget.userName;
    _loadCurrentUserProfile();
    _loadMessages();
    _startAutoRefresh();
    _setupSocketListeners();
    
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        _isAutoScrollEnabled = (maxScroll - currentScroll) < 100;
      }
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
          _currentUserRole = profileResult['data']['role']?.toString();
          _currentUserAvatar = profileResult['data']['avatar']?['url']?.toString();
          _currentUserName = profileResult['data']['fullName']?.toString();
        });
        print('✅ Current user profile loaded:');
        print('   ID: $_currentUserId');
        print('   Role: $_currentUserRole');
        print('   Avatar: $_currentUserAvatar');
        print('   Name: $_currentUserName');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket != null) {
      socket.on('call:incoming', (data) {
        print('📞 Incoming call event received: $data');
        if (data['chatId'] == widget.chatId && mounted) {
          _showIncomingCall(
            callerId: data['fromUserId'],
            callerName: data['callerName'] ?? widget.userName,
            callerAvatar: data['callerAvatar'] ?? _actualUserAvatar,
            isVideoCall: data['isVideo'] ?? true,
          );
        }
      });

      socket.on('message:new', (data) {
        if (data['chatId'] == widget.chatId && mounted) {
          _loadMessagesQuietly();
        }
      });
    }
  }

  void _showIncomingCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required bool isVideoCall,
  }) {
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          chatId: widget.chatId,
          callerName: callerName,
          callerAvatar: callerAvatar,
          callerId: callerId,
          isVideoCall: isVideoCall,
        ),
      ),
    );
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadMessagesQuietly();
      }
    });
  }

  Future<void> _loadMessagesQuietly() async {
    try {
      final result = await ApiService.getChatMessages(
        chatId: widget.chatId,
        page: 1,
        limit: 50,
      );

      if (result['success'] == true && mounted) {
        final newMessages = result['data']?['items'] ?? [];
        
        Set<String> newMessageIds = {};
        for (var msg in newMessages) {
          final msgId = msg['_id']?.toString();
          if (msgId != null) {
            newMessageIds.add(msgId);
          }
        }

        if (newMessageIds.length != _messageIds.length || 
            !newMessageIds.containsAll(_messageIds)) {
          setState(() {
            _messages = newMessages;
            _messageIds = newMessageIds;
          });
          
          if (_isAutoScrollEnabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ Quiet refresh error: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getChatMessages(
        chatId: widget.chatId,
        page: 1,
        limit: 50,
      );

      if (result['success'] == true) {
        final messages = result['data']?['items'] ?? [];
        
        Set<String> ids = {};
        for (var msg in messages) {
          final msgId = msg['_id']?.toString();
          if (msgId != null) {
            ids.add(msgId);
          }
        }
        
        setState(() {
          _messages = messages;
          _messageIds = ids;
          _isLoading = false;
        });

        if (_messages.isNotEmpty && _currentUserId != null) {
          for (var msg in _messages) {
            final senderId = msg['sender']?['_id']?.toString();
            if (senderId != null && senderId != _currentUserId) {
              setState(() {
                if (_resolvedOtherUserId == null) {
                  _resolvedOtherUserId = senderId;
                }
                _otherUserRole = msg['sender']?['role']?.toString();
                _actualUserAvatar = msg['sender']?['avatar']?['url']?.toString();
                _actualUserName = msg['sender']?['fullName']?.toString();
              });
              print('✅ Loaded real user data:');
              print('   Name: $_actualUserName');
              print('   Avatar: $_actualUserAvatar');
              print('   Role: $_otherUserRole');
              break;
            }
          }
        }
        
        print('✅ Loaded ${_messages.length} messages');
        print('✅ Other user ID: $_resolvedOtherUserId');
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } else {
        print('⚠️ Failed to load messages: ${result['message']}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    
    if (content.isEmpty && _selectedFiles.isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final result = await ApiService.sendMessage(
        chatId: widget.chatId,
        content: content,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        contentType: _selectedFiles.isNotEmpty ? 'file' : 'text',
      );

      if (result['success'] == true) {
        _controller.clear();
        setState(() {
          _selectedFiles = [];
          _isAutoScrollEnabled = true;
        });
        
        await _loadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
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
      print('Error picking image: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _startAudioCall() async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                  📞 STARTING AUDIO CALL                      ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    
    final targetUserId = _resolvedOtherUserId ?? widget.otherUserId;
    
    if (_currentUserId == null || targetUserId == null) {
      print('❌ Missing user IDs');
      print('   • Current: $_currentUserId');
      print('   • Target: $targetUserId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot start call - user ID not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Ensure socket is connected
    if (!SocketService.instance.isConnected) {
      print('⚠️ Socket not connected, attempting reconnect...');
      try {
        await SocketService.instance.connect(_currentUserId!);
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!SocketService.instance.isConnected) {
          throw Exception('Failed to connect');
        }
      } catch (e) {
        print('❌ Socket connection failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect to server'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final eventData = {
      'fromUserId': _currentUserId,
      'toUserId': targetUserId,
      'chatId': widget.chatId,
      'isVideo': false,
      'callerName': _currentUserName,
      'callerAvatar': _currentUserAvatar,
    };

    print('📤 Emitting call:request');
    print('   • Data: $eventData');

    try {
      await SocketService.instance.emit('call:request', eventData);
      print('✅ Event emitted successfully');
    } catch (e) {
      print('❌ Error emitting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate call'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('╚══════════════════════════════════════════════════════════════╝');

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(
            chatId: widget.chatId,
            userName: _actualUserName ?? widget.userName,
            userAvatar: _actualUserAvatar,
            otherUserId: targetUserId,
            isInitiator: true,
          ),
        ),
      );
    }
  }

  void _startVideoCall() async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                  📹 STARTING VIDEO CALL                      ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    
    final targetUserId = _resolvedOtherUserId ?? widget.otherUserId;
    
    if (_currentUserId == null || targetUserId == null) {
      print('❌ Missing user IDs');
      print('   • Current: $_currentUserId');
      print('   • Target: $targetUserId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot start call - user ID not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Ensure socket is connected
    if (!SocketService.instance.isConnected) {
      print('⚠️ Socket not connected, attempting reconnect...');
      try {
        await SocketService.instance.connect(_currentUserId!);
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!SocketService.instance.isConnected) {
          throw Exception('Failed to connect');
        }
      } catch (e) {
        print('❌ Socket connection failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect to server'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final eventData = {
      'fromUserId': _currentUserId,
      'toUserId': targetUserId,
      'chatId': widget.chatId,
      'isVideo': true,
      'callerName': _currentUserName,
      'callerAvatar': _currentUserAvatar,
    };

    print('📤 Emitting call:request');
    print('   • Data: $eventData');

    try {
      await SocketService.instance.emit('call:request', eventData);
      print('✅ Event emitted successfully');
    } catch (e) {
      print('❌ Error emitting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate call'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('╚══════════════════════════════════════════════════════════════╝');

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            chatId: widget.chatId,
            userName: _actualUserName ?? widget.userName,
            userAvatar: _actualUserAvatar,
            otherUserId: targetUserId,
            isInitiator: true,
          ),
        ),
      );
    }
  }

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != 'file:///' &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      return NetworkImage(avatarUrl);
    }
    return const AssetImage('assets/images/doctor.png');
  }

  ImageProvider _getCurrentUserAvatar() {
    if (_currentUserAvatar != null &&
        _currentUserAvatar!.isNotEmpty &&
        _currentUserAvatar != 'file:///' &&
        (_currentUserAvatar!.startsWith('http://') || 
         _currentUserAvatar!.startsWith('https://'))) {
      return NetworkImage(_currentUserAvatar!);
    }
    return const AssetImage('assets/images/profile.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _getAvatarImage(_actualUserAvatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _actualUserName ?? widget.userName,
                    style: const TextStyle(
                      color: Color(0xFF1B2C49),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _otherUserRole == 'doctor' ? 'Doctor' : 'Patient',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✅ Always show audio icon
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.black, size: 24),
            onPressed: _startAudioCall,
          ),
          // ✅ Always show video icon
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black, size: 28),
            onPressed: _startVideoCall,
          ),
          const SizedBox(width: 10),
        ],
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
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation with ${_actualUserName ?? widget.userName}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          if (_selectedFiles.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedFiles[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Type your message.......",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Colors.black87),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Color(0xFF1E61D4)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final String content = message['content']?.toString() ?? '';
    final String senderId = message['sender']?['_id']?.toString() ?? '';
    final String senderName = message['sender']?['fullName']?.toString() ?? 'Unknown';
    final String? senderAvatar = message['sender']?['avatar']?['url']?.toString();
    
    final bool isMe = _currentUserId != null && senderId == _currentUserId;
    
    final DateTime? createdAt = message['createdAt'] != null
        ? DateTime.tryParse(message['createdAt'].toString())
        : null;

    final List<dynamic> fileUrl = message['fileUrl'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: _getAvatarImage(senderAvatar),
              ),
            ),
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF7C69FF) : const Color(0xFFF1F4F7),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fileUrl.isNotEmpty)
                      ...fileUrl.map((file) {
                        final String? url = file['url']?.toString();
                        if (url != null && 
                            url.isNotEmpty &&
                            url != 'file:///' &&
                            (url.startsWith('http://') || url.startsWith('https://'))) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    
                    if (content.isNotEmpty && content.trim() != ' ')
                      Text(
                        content,
                        style: TextStyle(
                          color: isMe ? Colors.white : const Color(0xFF1B2C49),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              if (createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    _formatMessageTime(createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: _getCurrentUserAvatar(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
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
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    SocketService.instance.off('call:incoming');
    SocketService.instance.off('message:new');
    print('Auto-refresh stopped');
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String doctorName;
  final String? doctorAvatar;
  final String? doctorId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.doctorName,
    this.doctorAvatar,
    this.doctorId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  List<File> _selectedFiles = [];
  String? _currentUserId;
  String? _currentUserAvatar;
  String? _currentUserName;
  String? _otherUserId;
  String? _actualDoctorAvatar;
  String? _actualDoctorName;
  
  Timer? _refreshTimer;
  Set<String> _messageIds = {};
  bool _isAutoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _actualDoctorAvatar = widget.doctorAvatar;
    _actualDoctorName = widget.doctorName;
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
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
          _currentUserAvatar = profileResult['data']['avatar']?['url']?.toString();
          _currentUserName = profileResult['data']['fullName']?.toString();
        });
        print('✅ Current user profile loaded');
        print('   ID: $_currentUserId');
        print('   Name: $_currentUserName');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket != null) {
      socket.on('message:new', (data) {
        print('📨 New message received: $data');
        if (data['chatId'] == widget.chatId) {
          _loadMessagesQuietly();
        }
      });
      print('✅ Socket listeners setup');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _loadMessagesQuietly();
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
          if (msgId != null) newMessageIds.add(msgId);
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
    setState(() => _isLoading = true);

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
          if (msgId != null) ids.add(msgId);
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
                _otherUserId = senderId;
                _actualDoctorAvatar = msg['sender']?['avatar']?['url']?.toString();
                _actualDoctorName = msg['sender']?['fullName']?.toString();
              });
              break;
            }
          }
        }

        if (_otherUserId == null && widget.doctorId != null) {
          setState(() => _otherUserId = widget.doctorId);
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    
    if (content.isEmpty && _selectedFiles.isEmpty) return;
    if (_isSending) return;

    setState(() => _isSending = true);

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
            SnackBar(content: Text('Failed: ${result['message']}')),
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
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedFiles.add(File(image.path)));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _startAudioCall() async {
    print('📞 Starting audio call...');
    
    if (_currentUserId == null || _otherUserId == null) {
      print('❌ Missing user IDs');
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

    final socket = SocketService.instance.socket;
    if (socket == null || !socket.connected) {
      print('⚠️ Socket not connected');
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

    final eventData = {
      'fromUserId': _currentUserId,
      'toUserId': _otherUserId,
      'chatId': widget.chatId,
      'isVideo': false,
      'callerName': _currentUserName,
      'callerAvatar': _currentUserAvatar,
    };

    print('📤 Emitting call:request: $eventData');

    try {
      await SocketService.instance.emit('call:request', eventData);
      print('✅ Event emitted');
    } catch (e) {
      print('❌ Error emitting: $e');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(
            chatId: widget.chatId,
            userName: _actualDoctorName ?? widget.doctorName,
            userAvatar: _actualDoctorAvatar,
            otherUserId: _otherUserId!,
            isInitiator: true,
          ),
        ),
      );
    }
  }

  void _startVideoCall() async {
    print('📹 Starting video call...');
    
    if (_currentUserId == null || _otherUserId == null) {
      print('❌ Missing user IDs');
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

    final socket = SocketService.instance.socket;
    if (socket == null || !socket.connected) {
      print('⚠️ Socket not connected');
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

    final eventData = {
      'fromUserId': _currentUserId,
      'toUserId': _otherUserId,
      'chatId': widget.chatId,
      'isVideo': true,
      'callerName': _currentUserName,
      'callerAvatar': _currentUserAvatar,
    };

    print('📤 Emitting call:request: $eventData');

    try {
      await SocketService.instance.emit('call:request', eventData);
      print('✅ Event emitted');
    } catch (e) {
      print('❌ Error emitting: $e');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            chatId: widget.chatId,
            userName: _actualDoctorName ?? widget.doctorName,
            userAvatar: _actualDoctorAvatar,
            otherUserId: _otherUserId!,
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
    return const AssetImage('assets/images/doctor1.png');
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
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _getAvatarImage(_actualDoctorAvatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _actualDoctorName ?? widget.doctorName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Doctor',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.black, size: 24),
            onPressed: _startAudioCall,
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black, size: 28),
            onPressed: _startVideoCall,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Today", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildBubble(_messages[index]);
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
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Type your message.......",
                        hintStyle: TextStyle(color: Colors.grey),
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
                        : const Icon(Icons.send, color: Color(0xFF6C5CE7)),
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

  Widget _buildBubble(Map<String, dynamic> message) {
    final String text = message['content']?.toString() ?? '';
    final String senderId = message['sender']?['_id']?.toString() ?? '';
    final String? senderAvatar = message['sender']?['avatar']?['url']?.toString();
    final bool isMe = _currentUserId != null && senderId == _currentUserId;
    final List<dynamic> attachments = message['fileUrl'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(radius: 20, backgroundImage: _getAvatarImage(senderAvatar)),
          if (!isMe) const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF6C5CE7) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachments.isNotEmpty)
                  ...attachments.map((att) {
                    final String? url = att['url']?.toString();
                    if (url != null && url.isNotEmpty && url != 'file:///' &&
                        (url.startsWith('http://') || url.startsWith('https://'))) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, width: 200, height: 200, fit: BoxFit.cover),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) CircleAvatar(radius: 20, backgroundImage: _getCurrentUserAvatar()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    SocketService.instance.off('message:new');
    super.dispose();
  }
}
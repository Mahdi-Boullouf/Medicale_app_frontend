import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async'; // ✅ Timer এর জন্য
import 'package:image_picker/image_picker.dart';

class DoctorChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String userRole;

  const DoctorChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
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
  
  // ✅ Auto-refresh এর জন্য Timer
  Timer? _refreshTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadMessages();
    _startAutoRefresh(); // ✅ Auto-refresh চালু করো
  }

  // ✅ Auto-refresh timer - প্রতি 3 সেকেন্ডে নতুন message check করবে
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadMessagesQuietly(); // ✅ Loading indicator ছাড়া refresh
      }
    });
    print('✅ Auto-refresh started (every 3 seconds)');
  }

  // ✅ Quietly load messages - loading indicator ছাড়া
  Future<void> _loadMessagesQuietly() async {
    try {
      final result = await ApiService.getChatMessages(
        chatId: widget.chatId,
        page: 1,
        limit: 50,
      );

      if (result['success'] == true) {
        final newMessages = result['data']?['items'] ?? [];
        
        // ✅ শুধুমাত্র নতুন message থাকলেই update করো
        if (newMessages.length != _lastMessageCount) {
          setState(() {
            _messages = newMessages;
            _lastMessageCount = newMessages.length;
          });
          
          print('🔄 New message detected! Total: ${_messages.length}');
          
          // ✅ নতুন message এলে bottom এ scroll করো
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
    } catch (e) {
      print('❌ Quiet refresh error: $e');
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        // Parse the JSON string to get user data
        final userData = userDataString;
      }
      
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
        });
        print('✅ Current user ID: $_currentUserId');
      }
    } catch (e) {
      print('❌ Error loading current user ID: $e');
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
        setState(() {
          _messages = result['data']?['items'] ?? [];
          _lastMessageCount = _messages.length; // ✅ Count save করো
          _isLoading = false;
        });
        print('✅ Loaded ${_messages.length} messages');
        
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
        });
        
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${result['message']}')),
        );
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
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
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : const AssetImage('assets/images/doctor.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Color(0xFF1B2C49),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        widget.userRole == 'doctor' ? 'Doctor' : 'Patient',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      // ✅ Live indicator - auto-refresh চলছে
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✅ Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54, size: 22),
            onPressed: _loadMessages,
            tooltip: 'Refresh messages',
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.black, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon')),
              );
            },
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
                              'Start a conversation with ${widget.userName}',
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
                backgroundImage: senderAvatar != null
                    ? NetworkImage(senderAvatar)
                    : const AssetImage("assets/images/doctor.png") as ImageProvider,
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
                        if (url != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
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
                      }).toList(),
                    
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
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage("assets/images/profile.png"),
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
    _refreshTimer?.cancel(); // ✅ Timer বন্ধ করো
    _controller.dispose();
    _scrollController.dispose();
    print('✅ Auto-refresh stopped');
    super.dispose();
  }
}
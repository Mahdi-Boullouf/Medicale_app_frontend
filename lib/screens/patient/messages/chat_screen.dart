import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'dart:io';
import 'dart:async'; // ✅ Timer এর জন্য
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String doctorName;
  final String? doctorAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.doctorName,
    this.doctorAvatar,
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
  
  // ✅ Auto-refresh এর জন্য Timer
  Timer? _refreshTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
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
        
        if (_messages.isNotEmpty && _currentUserId == null) {
          _currentUserId = _messages.first['sender']?['_id'];
        }
        
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

  Widget _getAvatarWidget(String? avatarUrl, {bool isDoctor = false}) {
    if (avatarUrl != null && 
        avatarUrl.isNotEmpty && 
        avatarUrl != 'file:///' &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (exception, stackTrace) {
          print('⚠️ Failed to load avatar: $avatarUrl');
        },
        child: Container(),
      );
    }
    
    return CircleAvatar(
      radius: 20,
      backgroundImage: AssetImage(
        isDoctor ? 'assets/images/doctor1.png' : 'assets/images/profile.png'
      ),
    );
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
            _getAvatarWidget(widget.doctorAvatar, isDoctor: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Doctor',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      // ✅ Live indicator
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Today",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
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
                              'Start a conversation with ${widget.doctorName}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildBubble(_messages[index], index);
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
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
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
                  const SizedBox(width: 5),
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> message, int index) {
    final String text = message['content']?.toString() ?? '';
    final String senderId = message['sender']?['_id']?.toString() ?? '';
    final String senderName = message['sender']?['fullName']?.toString() ?? 'Unknown';
    final String? senderAvatar = message['sender']?['avatar']?['url']?.toString();
    
    final bool isMe = message['sender']?['role'] == 'patient';
    
    final List<dynamic> attachments = message['fileUrl'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                _getAvatarWidget(senderAvatar, isDoctor: true),
              const SizedBox(width: 8),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6C5CE7) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                    bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
                  ),
                  boxShadow: [
                    if (!isMe)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (attachments.isNotEmpty)
                      ...attachments.map((att) {
                        final String? url = att['url']?.toString();
                        if (url != null && url.isNotEmpty && url != 'file:///') {
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
              const SizedBox(width: 8),
              if (isMe)
                _getAvatarWidget(null, isDoctor: false),
            ],
          ),
          
          if (message['createdAt'] != null)
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 45,
                right: isMe ? 45 : 0,
                top: 5,
              ),
              child: Text(
                _formatTime(message['createdAt']),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
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
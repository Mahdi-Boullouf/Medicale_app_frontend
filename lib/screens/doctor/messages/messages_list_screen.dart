import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/doctor/messages/chat_screen.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorMessagesScreen extends StatefulWidget {
  const DoctorMessagesScreen({super.key});

  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  String selectedTab = "All";
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadChats();
  }

  // ✅ Load current user ID
  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        // Try to get from stored data first
        // You might need to parse JSON here based on how you store it
      }
      
      // Get from API as backup
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
        });
        print('✅ Current doctor ID: $_currentUserId');
      }
    } catch (e) {
      print('❌ Error loading current user ID: $e');
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading chats...');
      final result = await ApiService.getMyChats();
      
      print('📦 API Response: ${result.toString()}');
      
      if (result['success'] == true) {
        final chats = result['data'] ?? [];
        setState(() {
          _chats = chats is List ? chats : [];
          _isLoading = false;
        });
        print('✅ Loaded ${_chats.length} chats');
        
        // Debug: Print each chat
        for (var chat in _chats) {
          print('💬 Chat ID: ${chat['_id']}');
          print('   Participants: ${chat['participants']}');
        }
      } else {
        print('⚠️ Failed to load chats: ${result['message']}');
        setState(() {
          _chats = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading chats: $e');
      setState(() {
        _chats = [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredChats {
    if (_currentUserId == null) return _chats;
    
    if (selectedTab == "All") {
      return _chats;
    } else if (selectedTab == "Doctors") {
      return _chats.where((chat) {
        final participants = chat['participants'] as List?;
        if (participants == null) return false;
        
        // Check if there's any OTHER doctor in participants (not self)
        return participants.any((p) => 
          p['role'] == 'doctor' && 
          p['_id']?.toString() != _currentUserId
        );
      }).toList();
    } else {
      // Patient tab
      return _chats.where((chat) {
        final participants = chat['participants'] as List?;
        if (participants == null) return false;
        
        // Check if there's any patient in participants
        return participants.any((p) => p['role'] == 'patient');
      }).toList();
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DoctorMainNavigation()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayChats = _filteredChats;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _handleBack(context),
          ),
          title: const Text(
            "Messages",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // ✅ Add refresh button for debugging
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadChats,
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            // Tab Selection Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton("All"),
                    _buildTabButton("Doctors"),
                    _buildTabButton("Patient"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ✅ Debug info
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Loading chats...', style: TextStyle(color: Colors.grey)),
              ),
            if (!_isLoading && _chats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total chats: ${_chats.length}, Filtered: ${displayChats.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            
            // Chat List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadChats,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, 
                                    size: 64, 
                                    color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _chats.isEmpty 
                                    ? 'No conversations yet'
                                    : 'No ${selectedTab.toLowerCase()} conversations',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: displayChats.length,
                            itemBuilder: (context, index) {
                              return _buildChatItem(displayChats[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title) {
    final isSelected = selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = title),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E61D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1B2C49),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];
    
    print('🔍 Building chat item:');
    print('   Chat ID: ${chat['_id']}');
    print('   Participants count: ${participants.length}');
    print('   Current user ID: $_currentUserId');
    
    // ✅ Find the OTHER user (not me)
    final otherUser = participants.firstWhere(
      (p) => p['_id']?.toString() != _currentUserId,
      orElse: () => participants.isNotEmpty ? participants[0] : null,
    );
    
    if (otherUser == null) {
      print('⚠️ No other user found in chat');
      return const SizedBox.shrink();
    }
    
    final String name = otherUser['fullName']?.toString() ?? 'Unknown User';
    final String? avatarUrl = otherUser['avatar']?['url']?.toString();
    final String role = otherUser['role']?.toString() ?? '';
    
    print('   Other user: $name (role: $role)');
    
    final lastMessage = chat['lastMessage'];
    final String messageText = lastMessage != null 
        ? (lastMessage['content']?.toString() ?? 'No messages yet')
        : 'Start conversation';
    
    final DateTime? updatedAt = chat['updatedAt'] != null 
        ? DateTime.tryParse(chat['updatedAt'].toString())
        : null;
    final String timeText = updatedAt != null ? _formatTime(updatedAt) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          print('📱 Opening chat: ${chat['_id']}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorChatDetailScreen(
                chatId: chat['_id'].toString(),
                userName: name,
                userAvatar: avatarUrl,
                userRole: role,
              ),
            ),
          ).then((_) {
            print('🔄 Returned from chat, refreshing...');
            _loadChats();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/images/doctor.png') as ImageProvider,
                backgroundColor: Colors.grey[200],
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
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role == 'doctor')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        if (role == 'patient')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Patient',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      messageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
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
}
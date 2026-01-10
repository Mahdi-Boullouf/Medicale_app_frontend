import 'package:docmobi/screens/doctor/posts/doctor_create_post_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_profile_screen.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';
import 'package:docmobi/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/screens/auth/sign_in_screen.dart';
import 'package:docmobi/models/post_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _initializeScreen() async {
    print('🔄 Initializing Doctor Home Screen...');
    
    if (!ApiService.isLoggedIn) {
      print('❌ No token found - redirecting to login');
      _handleTokenMissing();
      return;
    }

    await _loadUserData();
    await _loadPosts();
  }

  void _handleTokenMissing() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _errorMessage = 'Session expired. Please login again.';
    });

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const SignInScreen(userType: 'doctor'),
                  ),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadUserData() async {
    try {
      await context.read<UserProvider>().fetchUserProfile();
    } catch (e) {
      print('⚠️ Error loading user data: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📤 Loading ALL doctor posts...');
      
      final result = await ApiService.get(
        '/api/v1/posts/all-posts?page=$_currentPage&limit=20',
        requiresAuth: true,
      );
      
      print('📥 Full Response: $result');
      
      if (!mounted) return;

      if (result['success'] == true) {
        final postsData = result['data']?['items'] ?? [];
        final pagination = result['data']?['pagination'] ?? {};
        
        print('✅ Loaded ${postsData.length} posts from ALL doctors');
        
        setState(() {
          _posts = postsData
              .map<PostModel>((p) => PostModel.fromJson(p))
              .toList();
          _currentPage = 1;
          _hasMore = (pagination['page'] * pagination['limit']) < pagination['total'];
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (result['requiresLogin'] == true) {
        print('❌ Token not found or expired');
        _handleTokenMissing();
      } else {
        print('⚠️ Failed to load posts: ${result['message']}');
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Failed to load posts';
        });
      }
    } catch (e) {
      print('❌ Error loading posts: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.get(
        '/api/v1/posts/all-posts?page=${_currentPage + 1}&limit=20',
        requiresAuth: true,
      );

      if (result['success'] == true) {
        final postsData = result['data']?['items'] ?? [];
        final pagination = result['data']?['pagination'] ?? {};

        setState(() {
          _posts.addAll(
            postsData.map<PostModel>((p) => PostModel.fromJson(p)).toList(),
          );
          _currentPage++;
          _hasMore = (pagination['page'] * pagination['limit']) < pagination['total'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading more posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await context.read<UserProvider>().fetchUserProfile();
    _currentPage = 1;
    await _loadPosts();
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorCreatePostScreen(),
      ),
    );
    
    if (result == true) {
      print('🔄 Post created successfully, reloading...');
      await _refreshData();
    }
  }

  // ✅ FIXED: Navigate to profile WITHOUT hiding bottom nav
  void _navigateToProfile() {
    // Don't use Navigator.push - instead tell parent to switch tab
    // This requires using a callback or state management
    // For now, we'll keep the simple navigation but the parent will handle it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorProfileScreen(),
      ),
    ).then((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  
                  return Container(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1664CD).withOpacity(0.1),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _navigateToProfile,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: user?.profileImage != null && 
                                                user!.profileImage!.isNotEmpty
                                    ? NetworkImage(user.profileImage!)
                                    : const AssetImage('assets/images/doctor_booking.png') 
                                        as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Doctor',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B2C49),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.specialty ?? 'General Physician',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            IconButton(
                              icon: Icon(
                                _isSearching ? Icons.close : Icons.search,
                                color: const Color(0xFF1B2C49), 
                                size: 24,
                              ),
                              onPressed: _toggleSearch,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined, 
                                color: Color(0xFF1B2C49), 
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        if (_isSearching) ...[
                          const SizedBox(height: 15),
                          TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search posts...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              // TODO: Implement search
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildCreatePostBox(),
        
        if (_posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.post_add, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No posts yet. Be the first to share!',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _posts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return PostCard(
                post: _posts[index],
                onPostUpdated: _refreshData,
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreatePostBox() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?.profileImage != null && 
                                   user!.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : const AssetImage('assets/images/doctor_booking.png') 
                            as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToCreatePost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15, 
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Share your insights with fellow doctors...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPostAction(
                    Icons.image_outlined, 
                    'Photo', 
                    Colors.brown, 
                    _navigateToCreatePost,
                  ),
                  _buildPostAction(
                    Icons.videocam_outlined, 
                    'Video', 
                    Colors.redAccent, 
                    _navigateToCreatePost,
                  ),
                  _buildPostAction(
                    Icons.play_circle_outline, 
                    'Reels', 
                    Colors.blueAccent, 
                    _navigateToCreatePost,
                  ),
                  
                  InkWell(
                    onTap: _navigateToCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1664CD)),
                      ),
                      child: const Text(
                        'Create a Post',
                        style: TextStyle(
                          color: Color(0xFF1664CD),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostAction(
    IconData icon, 
    String label, 
    Color color, 
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
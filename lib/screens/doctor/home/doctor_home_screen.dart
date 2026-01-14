import 'package:docmobi/screens/doctor/home/notifications/notifications.dart';
import 'package:docmobi/screens/doctor/messages/messages_list_screen.dart';
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
import 'dart:async';
import '../../../providers/notification_provider.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  List<PostModel> _posts = [];
  List<PostModel> _searchResults = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;
  String _currentSearchQuery = '';

  // For suggestion selection tracking
  int _selectedSuggestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore &&
        !_isSearching) {
      _loadMorePosts();
    }
  }

  // ✅ ENHANCED: Search debounce with minimum 1 character
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();

    // Clear results if query is empty
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions.clear();
        _searchResults.clear();
        _currentSearchQuery = '';
        _selectedSuggestionIndex = -1;
      });
      return;
    }

    // Trigger search after 300ms of no typing (faster response)
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  // ✅ ENHANCED: Perform search with better error handling
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearchLoading = true;
      _currentSearchQuery = query;
      _selectedSuggestionIndex = -1;
    });

    try {
      final result = await ApiService.get(
        '/api/v1/posts/search?q=${Uri.encodeComponent(query)}',
        requiresAuth: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final posts = result['data']?['posts'] ?? [];
        final suggestions = result['data']?['suggestions'] ?? [];
        final meta = result['data']?['meta'] ?? {};

        setState(() {
          _searchResults = posts
              .map<PostModel>((p) => PostModel.fromJson(p))
              .toList();
          _searchSuggestions = List<Map<String, dynamic>>.from(suggestions);
          _isSearchLoading = false;
        });

        print(
          '🔍 Search complete: ${_searchResults.length} posts, ${_searchSuggestions.length} suggestions',
        );
      } else {
        setState(() {
          _searchResults.clear();
          _searchSuggestions.clear();
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (!mounted) return;
      setState(() {
        _isSearchLoading = false;
        _searchResults.clear();
        _searchSuggestions.clear();
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initializeScreen() async {
    if (!ApiService.isLoggedIn) {
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
                    builder: (context) =>
                        const SignInScreen(userType: 'doctor'),
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
      final result = await ApiService.get(
        '/api/v1/posts/all-posts?page=$_currentPage&limit=20',
        requiresAuth: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final postsData = result['data']?['items'] ?? [];
        final pagination = result['data']?['pagination'] ?? {};

        setState(() {
          _posts = postsData
              .map<PostModel>((p) => PostModel.fromJson(p))
              .toList();
          _currentPage = 1;
          _hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (result['requiresLogin'] == true) {
        _handleTokenMissing();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Failed to load posts';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

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
          _hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
      MaterialPageRoute(builder: (context) => const DoctorCreatePostScreen()),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    ).then((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults.clear();
        _searchSuggestions.clear();
        _currentSearchQuery = '';
        _selectedSuggestionIndex = -1;
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _showDoctorInfo(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorInfoBottomSheet(doctor: doctor),
    );
  }

  // ✅ ENHANCED: Handle suggestion tap with different actions
  void _onSuggestionTap(Map<String, dynamic> suggestion) {
    final type = suggestion['type'];
    final data = suggestion['data'];

    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (type == 'doctor') {
      // Show doctor details in bottom sheet
      _showDoctorInfo(data);
    } else if (type == 'category') {
      // Search for this specialty
      final specialtyName = data['speciality_name'];
      _searchController.text = specialtyName;
      _performSearch(specialtyName);
    } else if (type == 'post') {
      // Scroll to this post in search results (already visible)
      // Or you can open a post detail screen if you have one
    }
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
            // ========== HEADER WITH SEARCH ==========
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
                                backgroundImage:
                                    user?.profileImage != null &&
                                        user!.profileImage!.isNotEmpty
                                    ? NetworkImage(user.profileImage!)
                                    : const AssetImage(
                                            'assets/images/doctor_booking.png',
                                          )
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
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                        builder: (context) =>
                                            const DoctorNotificationScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: context
                                      .read<NotificationProvider>()
                                      .generalUnreadCount,
                                  builder: (context, count, child) {
                                    if (count == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ✅ ENHANCED: Search bar with better UX
                        if (_isSearching) ...[
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText:
                                    'Search doctors, posts, specialties...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF1664CD),
                                  size: 22,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSearchLoading)
                                      const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    if (_searchController.text.isNotEmpty &&
                                        !_isSearchLoading)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      ),
                                  ],
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1664CD),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ========== SEARCH SUGGESTIONS ==========
            if (_isSearching &&
                _searchSuggestions.isNotEmpty &&
                _searchController.text.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Suggestions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _searchSuggestions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 60,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          final type = suggestion['type'];
                          final text = suggestion['text'] ?? '';
                          final subtext = suggestion['subtext'] ?? '';

                          IconData icon;
                          Color iconColor;
                          Color bgColor;

                          switch (type) {
                            case 'doctor':
                              icon = Icons.person;
                              iconColor = const Color(0xFF1664CD);
                              bgColor = const Color(
                                0xFF1664CD,
                              ).withOpacity(0.1);
                              break;
                            case 'category':
                              icon = Icons.medical_services;
                              iconColor = const Color(0xFFFF9800);
                              bgColor = const Color(
                                0xFFFF9800,
                              ).withOpacity(0.1);
                              break;
                            case 'post':
                              icon = Icons.article;
                              iconColor = const Color(0xFF4CAF50);
                              bgColor = const Color(
                                0xFF4CAF50,
                              ).withOpacity(0.1);
                              break;
                            default:
                              icon = Icons.search;
                              iconColor = Colors.grey;
                              bgColor = Colors.grey.withOpacity(0.1);
                          }

                          return InkWell(
                            onTap: () => _onSuggestionTap(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 20,
                                      color: iconColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1B2C49),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (subtext.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtext,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.north_west,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ========== MAIN CONTENT ==========
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // ✅ Show search results when searching
    if (_isSearching) {
      if (_isSearchLoading && _searchController.text.isNotEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(50.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Searching...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      if (_searchController.text.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1664CD).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  size: 60,
                  color: Color(0xFF1664CD),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Search for anything',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2C49),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find doctors, posts, or specialties',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      }

      if (_searchResults.isEmpty && !_isSearchLoading) {
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No results found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2C49),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      }

      // Show search results
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.article, size: 20, color: Color(0xFF1664CD)),
                const SizedBox(width: 8),
                Text(
                  'Posts (${_searchResults.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return PostCard(
                post: _searchResults[index],
                onPostUpdated: () {
                  _performSearch(_currentSearchQuery);
                },
                onAuthorTap: (authorData) {
                  _showDoctorInfo(authorData);
                },
              );
            },
          ),
        ],
      );
    }

    // ✅ Show normal feed when not searching
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
                onAuthorTap: (authorData) {
                  _showDoctorInfo(authorData);
                },
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
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        user?.profileImage != null &&
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

// ✅ ENHANCED: Doctor Info Bottom Sheet
class DoctorInfoBottomSheet extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorInfoBottomSheet({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final String doctorName = doctor['fullName'] ?? 'Doctor';
    final String? doctorImage = doctor['avatar']?['url'];
    final String doctorId = doctor['_id'] ?? '';
    final String specialty = doctor['specialty'] ?? 'General Physician';
    final String bio = doctor['bio'] ?? 'No bio available';
    final int experienceYears = doctor['experienceYears'] ?? 0;
    final List degrees = doctor['degrees'] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 50,
              backgroundImage: doctorImage != null
                  ? NetworkImage(doctorImage)
                  : const AssetImage('assets/images/doctor.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 16),

            Text(
              doctorName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Specialty
            Text(
              specialty,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            if (experienceYears > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1664CD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$experienceYears years of experience',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1664CD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            if (bio != 'No bio available')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bio,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),

            if (degrees.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: degrees.map<Widget>((degree) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1664CD).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      degree['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1664CD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorMessagesScreen(initialDoctorId: doctorId),
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text(
                  'Message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

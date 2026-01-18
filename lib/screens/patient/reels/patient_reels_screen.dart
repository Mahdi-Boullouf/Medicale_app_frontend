import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'dart:async';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class PatientReelsScreen extends StatefulWidget {
  const PatientReelsScreen({super.key});

  @override
  State<PatientReelsScreen> createState() => _PatientReelsScreenState();
}

class _PatientReelsScreenState extends State<PatientReelsScreen> {
  List<Map<String, dynamic>> reelsList = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReels();
    _scrollController.addListener(_onScroll);

    // ✅ Auto refresh every 1 second
    // ✅ Auto refresh every 30 seconds (not 1 second!)
    // ✅ Auto refresh every 30 seconds with silent update
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadReels();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // ✅ এই লাইন add করো
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMore) {
      _loadMoreReels();
    }
  }

  Future<void> _loadReels() async {
    // ✅ Don't show loading if already have data (prevents blink)
    if (reelsList.isEmpty) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      debugPrint('📤 Loading reels...');
      final response = await ApiService.getAllReels(page: 1, limit: 20);

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList = items
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = 1;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
        debugPrint('✅ Loaded ${reelsList.length} reels');
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      // ✅ Only show error if list is empty
      if (reelsList.isEmpty) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReels() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getAllReels(
        page: currentPage + 1,
        limit: 20,
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList.addAll(
            items.map((item) => item as Map<String, dynamic>).toList(),
          );
          currentPage++;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more reels: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    await _loadReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            // ✅ REDIRECT: Go back to home screen (PatientMainNavigation)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReels,
        child: isLoading && reelsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load reels'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadReels,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : reelsList.isEmpty
            ? const Center(child: Text('No reels available'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reelsList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reelsList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildReelThumbnail(reelsList[index], index);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildReelThumbnail(Map<String, dynamic> reel, int index) {
    final thumbnailUrl = reel['thumbnail']?['url'];
    final author = reel['author'];
    final doctorName = author?['fullName'] ?? 'Unknown Doctor';
    final caption = reel['caption'] ?? '';
    final likesCount = reel['likesCount'] ?? 0;

    return GestureDetector(
      onTap: () async {
        // ✅ Wait for result from viewer (to get updated data)
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReelsViewerScreen(reelsList: reelsList, initialIndex: index),
          ),
        );

        // ✅ Refresh if needed
        if (result == true) {
          _loadReels();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),

          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✅ Show thumbnail with loading indicator

              // ✅ Load video first frame if no thumbnail
              FutureBuilder<Uint8List?>(
                future: _generateThumbnail(thumbnailUrl, reel['video']?['url']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  // If we generated a thumbnail from video
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }

                  // Fallback to network thumbnail if available
                  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
                    return Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.videocam,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    );
                  }

                  // No thumbnail at all
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.videocam,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),

              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(likesCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Generate thumbnail from video
  Future<Uint8List?> _generateThumbnail(
    String? thumbnailUrl,
    String? videoUrl,
  ) async {
    try {
      // First try to load existing thumbnail
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        return null; // Let Image.network handle it
      }

      // If no thumbnail, generate from video
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoUrl,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          quality: 75,
        );
        return uint8list;
      }
    } catch (e) {
      print('❌ Error generating thumbnail: $e');
    }
    return null;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ✅ NEW: Reel Comments Bottom Sheet
class ReelCommentsBottomSheet extends StatefulWidget {
  final String reelId;
  final VoidCallback? onCommentAdded;

  const ReelCommentsBottomSheet({
    super.key,
    required this.reelId,
    this.onCommentAdded,
  });

  @override
  State<ReelCommentsBottomSheet> createState() =>
      _ReelCommentsBottomSheetState();
}

class _ReelCommentsBottomSheetState extends State<ReelCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final result = await ApiService.getReelComments(
        reelId: widget.reelId,
        page: 1,
        limit: 50,
      );

      if (result['success'] == true) {
        final items = result['data']['items'] as List;
        setState(() {
          _comments = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reel comments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.addReelComment(
        reelId: widget.reelId,
        content: text,
      );

      if (result['success'] == true) {
        _commentController.clear();
        widget.onCommentAdded?.call();
        await _loadComments();
      }
    } catch (e) {
      debugPrint('❌ Error submitting reel comment: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final author = comment['author'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: author?['avatar']?['url'] != null
                                ? NetworkImage(author['avatar']['url'])
                                : const AssetImage(
                                        'assets/images/doctor_booking.png',
                                      )
                                      as ImageProvider,
                          ),
                          title: Text(
                            author?['fullName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['content'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(comment['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1664CD),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isSubmitting ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Just now';

    try {
      final date = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}

class ReelsViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> reelsList;
  final int initialIndex;

  const ReelsViewerScreen({
    super.key,
    required this.reelsList,
    required this.initialIndex,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  late PageController _pageController;
  late int currentPage;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _likedReels = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, int> _shareCounts = {};
  bool _showControls = false;
  Timer? _controlsTimer;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoForPage(currentPage);

    for (var reel in widget.reelsList) {
      final reelId = reel['_id'] ?? '';
      _likedReels[reelId] = reel['isLiked'] ?? false;
      _likeCounts[reelId] = reel['likesCount'] ?? 0;
      _commentCounts[reelId] = reel['commentsCount'] ?? 0;
      _shareCounts[reelId] = reel['sharesCount'] ?? 0;
    }

    // ✅ Show controls initially for 3 seconds
    _showControls = true;
    _startHideControlsTimer();
  }

  Future<void> _initializeVideoForPage(int index) async {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
      return;
    }

    final videoUrl = widget.reelsList[index]['video']?['url'];
    if (videoUrl == null) {
      print('❌ No video URL at index $index');
      return;
    }

    print('🎥 Loading video: $videoUrl');

    final controller = VideoPlayerController.network(videoUrl);
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      if (mounted && currentPage == index) {
        controller.play();
        setState(() {});
      }
      debugPrint('✅ Video loaded successfully at index $index');
    } catch (e) {
      debugPrint('❌ Error initializing video at index $index: $e');
    }
  }

  void _pauseAllExcept(int index) {
    _videoControllers.forEach((key, controller) {
      if (key != index) {
        controller.pause();
      }
    });
  }

  // ✅ UPDATED: Realtime like with proper response handling
  Future<void> _toggleLike(String reelId) async {
    // ✅ Optimistic update
    final wasLiked = _likedReels[reelId] ?? false;
    setState(() {
      _likedReels[reelId] = !wasLiked;
      _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? -1 : 1);
    });

    try {
      final result = await ApiService.likeReel(reelId);

      if (result['success'] == true) {
        // ✅ Update with server response
        final data = result['data'];
        setState(() {
          _likedReels[reelId] = data['isLiked'] ?? !wasLiked;
          _likeCounts[reelId] = data['likesCount'] ?? _likeCounts[reelId];
        });
      } else {
        // ✅ Revert on failure
        setState(() {
          _likedReels[reelId] = wasLiked;
          _likeCounts[reelId] =
              (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    } catch (e) {
      debugPrint('❌ Error liking reel: $e');
      // ✅ Revert on error
      setState(() {
        _likedReels[reelId] = wasLiked;
        _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to like reel'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ UPDATED: Share with count increment
  Future<void> _shareReel(Map<String, dynamic> reel) async {
    final author = reel['author'];
    final caption = reel['caption'] ?? '';
    final doctorName = author?['fullName'] ?? 'Unknown Doctor';
    final reelId = reel['_id'] ?? '';

    String shareText = '$doctorName shared a reel\n\n';
    if (caption.isNotEmpty) {
      shareText += caption;
    }

    try {
      await Share.share(shareText);

      // ✅ Increment share count locally
      setState(() {
        _shareCounts[reelId] = (_shareCounts[reelId] ?? 0) + 1;
      });

      // TODO: Call API to increment share count on backend
      // await ApiService.shareReel(reelId);
    } catch (e) {
      debugPrint('❌ Error sharing: $e');
    }
  }

  void _showComments(String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReelCommentsBottomSheet(
        reelId: reelId,
        onCommentAdded: () {
          // ✅ Update comment count instantly
          setState(() {
            _commentCounts[reelId] = (_commentCounts[reelId] ?? 0) + 1;
          });
        },
      ),
    );
  }

  // ✅ Show controls and start auto-hide timer
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  // ✅ Toggle controls visibility
  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  // ✅ Seek forward 5 seconds
  void _seekForward(VideoPlayerController controller) {
    final currentPosition = controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 5);
    final maxDuration = controller.value.duration;

    if (newPosition < maxDuration) {
      controller.seekTo(newPosition);
    } else {
      controller.seekTo(maxDuration);
    }

    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  // ✅ Seek backward 5 seconds
  void _seekBackward(VideoPlayerController controller) {
    final currentPosition = controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 5);

    if (newPosition > Duration.zero) {
      controller.seekTo(newPosition);
    } else {
      controller.seekTo(Duration.zero);
    }

    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  // ✅ Toggle play/pause
  void _togglePlayPause(VideoPlayerController controller) {
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  // ✅ Set playback speed (2x on long press)
  void _setPlaybackSpeed(VideoPlayerController controller, double speed) {
    controller.setPlaybackSpeed(speed);
    if (speed > 1.0) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controlsTimer?.cancel();
    _hideControlsTimer?.cancel(); // ✅ ADD THIS LINE
    _pageController.dispose();
    _videoControllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.reelsList.length,
        onPageChanged: (index) {
          setState(() => currentPage = index);
          _pauseAllExcept(index);
          _initializeVideoForPage(index);
        },
        itemBuilder: (context, index) =>
            _buildReelPage(widget.reelsList[index], index),
      ),
    );
  }

  Widget _buildReelPage(Map<String, dynamic> reel, int index) {
    final author = reel['author'];
    final doctorName = author?['fullName'] ?? 'Unknown Doctor';
    final specialty = author?['specialty'] ?? '';
    final caption = reel['caption'] ?? '';
    final avatarUrl = author?['avatar']?['url'];
    final videoController = _videoControllers[index];
    final reelId = reel['_id'] ?? '';
    final isLiked = _likedReels[reelId] ?? false;
    final likesCount = _likeCounts[reelId] ?? 0;
    final commentsCount = _commentCounts[reelId] ?? 0;
    final sharesCount = _shareCounts[reelId] ?? 0;

    return Stack(
      children: [
        // ✅ Enhanced video player with controls
        // ✅ Enhanced video player with FULL controls
        Positioned.fill(
          child: videoController != null && videoController.value.isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Player
                    Center(
                      child: AspectRatio(
                        aspectRatio: videoController.value.aspectRatio,
                        child: VideoPlayer(videoController),
                      ),
                    ),

                    // ✅ Full screen tap detector
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleControls(),
                      onLongPress: () =>
                          _setPlaybackSpeed(videoController, 2.0),
                      onLongPressEnd: (_) =>
                          _setPlaybackSpeed(videoController, 1.0),
                      child: Container(color: Colors.transparent),
                    ),

                    // ✅ Control buttons (only show when _showControls is true)
                    if (_showControls) ...[
                      // LEFT - Rewind button
                      Positioned(
                        left: 60,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _seekBackward(videoController),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.replay,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '5s',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // CENTER - Play/Pause button
                      Center(
                        child: GestureDetector(
                          onTap: () => _togglePlayPause(videoController),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ),
                      ),

                      // RIGHT - Forward button
                      Positioned(
                        right: 60,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _seekForward(videoController),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '5s',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ✅ 2x Speed indicator
                    if (videoController.value.playbackSpeed > 1.0)
                      Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fast_forward,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${videoController.value.playbackSpeed}x Speed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ✅ Bottom progress bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              videoController,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.white,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ValueListenableBuilder(
                                  valueListenable: videoController,
                                  builder:
                                      (context, VideoPlayerValue value, child) {
                                        return Text(
                                          '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),

        // ✅ Back button
        Positioned(
          top: 50,
          left: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // ✅ UPDATED: Action buttons with realtime counts
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _buildActionButton(
                isLiked ? Icons.favorite : Icons.favorite_border,
                _formatCount(likesCount),
                isLiked ? Colors.red : Colors.white,
                () => _toggleLike(reelId),
              ),
              const SizedBox(height: 25),
              _buildActionButton(
                Icons.chat_bubble_outline,
                _formatCount(commentsCount),
                Colors.white,
                () => _showComments(reelId),
              ),
              const SizedBox(height: 25),
              _buildActionButton(
                Icons.share_outlined,
                _formatCount(sharesCount),
                Colors.white,
                () => _shareReel(reel),
              ),
              const SizedBox(height: 25),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          right: 80,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (specialty.isNotEmpty)
                          Text(
                            specialty,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

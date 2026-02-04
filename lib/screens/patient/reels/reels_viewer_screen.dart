import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'widgets/reels_comments_bottom_sheet.dart';

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
      return;
    }

    final controller = VideoPlayerController.network(videoUrl);
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      if (mounted && currentPage == index) {
        controller.play();
        setState(() {});
      }
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

  Future<void> _toggleLike(String reelId) async {
    final wasLiked = _likedReels[reelId] ?? false;
    setState(() {
      _likedReels[reelId] = !wasLiked;
      _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? -1 : 1);
    });

    try {
      final result = await ApiService.likeReel(reelId);

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _likedReels[reelId] = data['isLiked'] ?? !wasLiked;
          _likeCounts[reelId] = data['likesCount'] ?? _likeCounts[reelId];
        });
      } else {
        setState(() {
          _likedReels[reelId] = wasLiked;
          _likeCounts[reelId] =
              (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    } catch (e) {
      debugPrint('❌ Error liking reel: $e');
      setState(() {
        _likedReels[reelId] = wasLiked;
        _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedLikeReel),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          setState(() {
            _commentCounts[reelId] = (_commentCounts[reelId] ?? 0) + 1;
          });
        },
      ),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

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

  void _togglePlayPause(VideoPlayerController controller) {
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

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

    _hideControlsTimer?.cancel();
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
    final doctorName =
        author?['fullName'] ?? AppLocalizations.of(context)!.unknownDoctor;
    final specialty = author?['specialty'] ?? '';
    final caption = reel['caption'] ?? '';
    final avatarUrl = author?['avatar']?['url'];
    final videoController = _videoControllers[index];
    final reelId = reel['_id'] ?? '';
    final isLiked = _likedReels[reelId] ?? false;
    final likesCount = _likeCounts[reelId] ?? 0;
    final commentsCount = _commentCounts[reelId] ?? 0;

    return Stack(
      children: [
        Positioned.fill(
          child: videoController != null && videoController.value.isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: videoController.value.aspectRatio,
                        child: VideoPlayer(videoController),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleControls(),
                      onLongPress: () =>
                          _setPlaybackSpeed(videoController, 2.0),
                      onLongPressEnd: (_) =>
                          _setPlaybackSpeed(videoController, 1.0),
                      child: Container(color: Colors.transparent),
                    ),
                    if (_showControls) ...[
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
                                  AppLocalizations.of(context)!.playbackSpeed(
                                    videoController.value.playbackSpeed
                                        .toString(),
                                  ),
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

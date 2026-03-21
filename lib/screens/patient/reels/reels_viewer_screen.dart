import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'widgets/reels_comments_bottom_sheet.dart';
import '../../../widgets/report_block_sheet.dart';

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
    }
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

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      if (mounted && currentPage == index) {
        controller.play();
        setState(() {});
      }
    } catch (e) {
      debugPrint(' Error initializing video at index $index: $e');
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
      debugPrint('Error liking reel: $e');
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

  @override
  void dispose() {
    _pageController.dispose();
    _videoControllers.forEach((_, controller) {
      controller.dispose();
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
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
        itemBuilder: (context, index) => ReelItemWidget(
          reel: widget.reelsList[index],
          controller: _videoControllers[index],
          isLiked: _likedReels[widget.reelsList[index]['_id']] ?? false,
          likesCount: _likeCounts[widget.reelsList[index]['_id']] ?? 0,
          commentsCount: _commentCounts[widget.reelsList[index]['_id']] ?? 0,
          onLike: () => _toggleLike(widget.reelsList[index]['_id']),
          onComment: () => _showComments(widget.reelsList[index]['_id']),
          onBack: () => Navigator.pop(context, true),
        ),
      ),
    );
  }
}

class ReelItemWidget extends StatefulWidget {
  final Map<String, dynamic> reel;
  final VideoPlayerController? controller;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBack;

  const ReelItemWidget({
    super.key,
    required this.reel,
    this.controller,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
    required this.onLike,
    required this.onComment,
    required this.onBack,
  });

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  bool _showControls = false;
  Timer? _hideControlsTimer;
  bool _showLikeAnimation = false;
  bool _showCenterIcon = false;
  IconData _centerIcon = Icons.play_arrow;

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _togglePlayPause() {
    if (widget.controller == null) return;
    setState(() {
      if (widget.controller!.value.isPlaying) {
        widget.controller!.pause();
        _centerIcon = Icons.pause;
      } else {
        widget.controller!.play();
        _centerIcon = Icons.play_arrow;
      }
      _showCenterIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showCenterIcon = false);
    });
  }

  void _onDoubleTap() {
    if (!widget.isLiked) {
      widget.onLike();
    }
    setState(() => _showLikeAnimation = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLikeAnimation = false);
    });
  }

  void _seek(int seconds) {
    if (widget.controller == null) return;
    final currentPosition = widget.controller!.value.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    widget.controller!.seekTo(newPosition);

    setState(() {
      _centerIcon = seconds > 0 ? Icons.fast_forward : Icons.fast_rewind;
      _showCenterIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showCenterIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.reel['author'];
    final doctorName =
        author?['fullName'] ?? AppLocalizations.of(context)!.unknownDoctor;
    final specialty = author?['specialty'] ?? '';
    final caption = widget.reel['caption'] ?? '';
    final avatarUrl = author?['avatar']?['url'];

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _startHideControlsTimer();
      },
      onDoubleTap: _onDoubleTap,
      onLongPressStart: (_) => widget.controller?.setPlaybackSpeed(2.0),
      onLongPressEnd: (_) => widget.controller?.setPlaybackSpeed(1.0),
      child: Stack(
        children: [
          Positioned.fill(
            child:
                widget.controller != null &&
                    widget.controller!.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: widget.controller!.value.aspectRatio,
                      child: VideoPlayer(widget.controller!),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),
          if (_showCenterIcon)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(_centerIcon, color: Colors.white, size: 40),
              ),
            ),
          if (_showLikeAnimation)
            const Center(
              child: Icon(Icons.favorite, color: Colors.red, size: 100),
            ),
          if (_showControls) ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.replay_5,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () => _seek(-5),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.controller?.value.isPlaying ?? false
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 70,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_5,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () => _seek(5),
                  ),
                ],
              ),
            ),
          ],
          if (widget.controller?.value.playbackSpeed == 2.0)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.playbackSpeed('2.0'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onBack,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                          ],
                        ),
                        if (caption.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _ActionButton(
                        icon: widget.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: _formatCount(widget.likesCount),
                        color: widget.isLiked ? Colors.red : Colors.white,
                        onTap: widget.onLike,
                      ),
                      const SizedBox(height: 20),
                      _ActionButton(
                        icon: Icons.comment,
                        label: _formatCount(widget.commentsCount),
                        onTap: widget.onComment,
                      ),
                      const SizedBox(height: 20),
                      _ActionButton(
                        icon: Icons.more_vert,
                        label: '',
                        onTap: () {
                          widget.controller?.pause();
                          ReportBlockSheet.show(
                            context,
                            reportedUserId: author?['_id'] ?? '',
                            itemType: 'Reel',
                            itemId: widget.reel['_id'] ?? '',
                            onBlocked: () {
                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                          ).then((_) {
                            if (mounted) {
                              widget.controller?.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              widget.controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF1664CD),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

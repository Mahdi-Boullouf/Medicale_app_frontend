import 'package:flutter/material.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/models/post_model.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/user_provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:docmobi/widgets/custom_image.dart';
import 'package:docmobi/widgets/full_screen_image_viewer.dart';
import 'package:docmobi/widgets/report_block_sheet.dart'; // ✅ UGC Safety

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onPostUpdated;
  final Function(Map<String, dynamic>)? onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onPostUpdated,
    this.onAuthorTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late PostModel _currentPost;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLiking = false;
  bool _isMuted = true;
  bool _isVisible = true; // ✅ Set to false instantly after blocking

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    final videoMedia = _currentPost.media.where((m) => m.isVideo).firstOrNull;
    if (videoMedia != null) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(videoMedia.url))
            ..setVolume(0)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });
              }
            });
    }
  }

  void _toggleMute() {
    if (_videoController != null) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0 : 1);
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      final result = await ApiService.likePost(_currentPost.id);

      if (result['success'] == true) {
        setState(() {
          _currentPost = _currentPost.copyWith(
            isLiked: !_currentPost.isLiked,
            likesCount: _currentPost.isLiked
                ? _currentPost.likesCount - 1
                : _currentPost.likesCount + 1,
          );
        });
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? l10n.failedLikePost),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' Error toggling like: $e');
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _showMoreOptions(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwnPost = currentUser?.id == _currentPost.author.id;

    if (!isOwnPost) {
      // ✅ For other users' posts: use the Report/Block sheet
      ReportBlockSheet.show(
        context,
        reportedUserId: _currentPost.author.id,
        itemType: 'Post',
        itemId: _currentPost.id,
        onBlocked: () {
          // Instantly hide this card from the feed
          if (mounted) setState(() => _isVisible = false);
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Own post: only show Delete
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.deletePost,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text(AppLocalizations.of(context)!.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deletePost),
          content: Text(l10n.confirmDeletePost),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePost();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    try {
      final result = await ApiService.deletePost(_currentPost.id);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postDeletedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onPostUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? l10n.failedDeletePost),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' Error deleting post: $e');
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsBottomSheet(
        postId: _currentPost.id,
        onCommentAdded: () {
          setState(() {
            _currentPost = _currentPost.copyWith(
              commentsCount: _currentPost.commentsCount + 1,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Instantly hide this card if user was blocked
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _handleAuthorTap(),
                  child: ClipOval(
                    child: CustomImage(
                      imageUrl: _currentPost.author.avatar,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholderAsset: 'assets/images/doctor_booking.png',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleAuthorTap(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _currentPost.author.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentPost.author.role == 'doctor')
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${_currentPost.author.specialty ?? AppLocalizations.of(context)!.doctor} • ${_currentPost.timeAgo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
          ),

          if (_currentPost.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(
                _currentPost.content,
                style: const TextStyle(fontSize: 14),
              ),
            ),

          if (_currentPost.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMediaSection(),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.likesCount(_currentPost.likesCount),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.commentsCount(_currentPost.commentsCount),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                // Text(
                //   AppLocalizations.of(
                //     context,
                //   )!.sharesCount(_currentPost.sharesCount),
                //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                // ),
              ],
            ),
          ),

          const Divider(height: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: _currentPost.isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: AppLocalizations.of(context)!.likeLabel,
                color: _currentPost.isLiked ? Colors.red : Colors.grey,
                onTap: _toggleLike,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: AppLocalizations.of(context)!.commentLabel,
                color: Colors.grey,
                onTap: _showComments,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAuthorTap() {
    if (widget.onAuthorTap != null) {
      widget.onAuthorTap!({
        '_id': _currentPost.author.id,
        'fullName': _currentPost.author.fullName,
        'avatar': _currentPost.author.avatar != null
            ? {'url': _currentPost.author.avatar}
            : null,
        'specialty': _currentPost.author.specialty,
        'bio': _currentPost.author.bio,
        'experienceYears': _currentPost.author.experienceYears,
        'degrees': _currentPost.author.degrees,
        'role': _currentPost.author.role,
      });
    }
  }

  void _openFullScreenImage(List<PostMedia> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: images.map((m) => m.url).toList(),
          initialIndex: index,
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final images = _currentPost.media.where((m) => m.isImage).toList();
    final videos = _currentPost.media.where((m) => m.isVideo).toList();

    if (videos.isNotEmpty) {
      return _buildVideoPlayerWithThumbnail(videos.first);
    }

    if (images.length == 1) {
      return _buildSingleImage(images.first);
    }

    return _buildMultipleImages(images);
  }

  Widget _buildVideoPlayerWithThumbnail(PostMedia video) {
    if (!_isVideoInitialized || _videoController == null) {
      return Stack(
        children: [
          if (video.thumbnail != null)
            CustomImage(
              imageUrl: video.thumbnail,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            )
          else
            Container(height: 250, color: Colors.grey[300]),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),

        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage(PostMedia image) {
    return GestureDetector(
      onTap: () => _openFullScreenImage([image], 0),
      child: ClipRRect(
        child: CustomImage(
          imageUrl: image.url,
          width: double.infinity,
          fit: BoxFit.cover,
          height: 200,
        ),
      ),
    );
  }

  Widget _buildMultipleImages(List<PostMedia> images) {
    if (images.length == 2) {
      return Row(
        children: images
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: GestureDetector(
                    onTap: () => _openFullScreenImage(images, entry.key),
                    child: CustomImage(
                      imageUrl: entry.value.url,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: images.length > 6 ? 6 : images.length,
      itemBuilder: (context, index) {
        if (index == 5 && images.length > 6) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomImage(
                imageUrl: images[index].url,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
              Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    '+${images.length - 6}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return GestureDetector(
          onTap: () => _openFullScreenImage(images, index),
          child: CustomImage(imageUrl: images[index].url, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final result = await ApiService.getPostComments(
        postId: widget.postId,
        page: 1,
        limit: 50,
      );

      if (result['success'] == true) {
        final items = result['data']['items'] as List;
        setState(() {
          _comments = items.map((item) => PostComment.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(' Error loading comments: $e');
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
      final result = await ApiService.addPostComment(
        postId: widget.postId,
        content: text,
      );

      if (result['success'] == true) {
        _commentController.clear();
        widget.onCommentAdded?.call();
        await _loadComments();
      }
    } catch (e) {
      debugPrint(' Error submitting comment: $e');
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
                  Text(
                    AppLocalizations.of(context)!.commentsLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.noCommentsYet),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: comment.author.avatar != null
                                ? NetworkImage(comment.author.avatar!)
                                : const AssetImage(
                                        'assets/images/doctor_booking.png',
                                      )
                                      as ImageProvider,
                          ),
                          title: Text(
                            comment.author.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.content),
                              const SizedBox(height: 4),
                              Text(
                                comment.timeAgo,
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
                          hintText: AppLocalizations.of(context)!.writeComment,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
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
}

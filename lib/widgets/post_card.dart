import 'package:flutter/material.dart';
import 'package:docmobi/models/post_model.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late PostModel _currentPost;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLiking = false;
  bool _isMuted = true; // ✅ Start muted by default
  
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
      _videoController = VideoPlayerController.network(videoMedia.url)
        ..setVolume(1) // ✅ Start UNMUTED
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
              _isMuted = false; // ✅ Set unmuted
            });
          }
        });
    }
  }

  // ✅ NEW: Toggle mute/unmute
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to like post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _showMoreOptions(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwnPost = currentUser?.id == _currentPost.author.id;

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
              if (isOwnPost) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Report Post'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report - Coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      final result = await ApiService.deletePost(_currentPost.id);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Post deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onPostUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error deleting post: $e');
    }
  }

  void _showShareOptions() {
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Share Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share Externally'),
                onTap: () {
                  Navigator.pop(context);
                  _shareExternal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share to message - Coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareExternal() async {
    try {
      String shareText = '${_currentPost.author.fullName} posted:\n\n';
      shareText += _currentPost.content;
      
      if (_currentPost.media.isNotEmpty) {
        final images = _currentPost.media.where((m) => m.isImage).toList();
        final videos = _currentPost.media.where((m) => m.isVideo).toList();
        
        if (images.isNotEmpty) {
          shareText += '\n\n📷 ${images.length} image(s)';
        }
        if (videos.isNotEmpty) {
          shareText += '\n\n🎥 ${videos.length} video(s)';
        }
      }

      await Share.share(shareText);
    } catch (e) {
      print('❌ Error sharing: $e');
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
          // ✅ Update comment count instantly
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _currentPost.author.avatar != null
                      ? NetworkImage(_currentPost.author.avatar!)
                      : const AssetImage('assets/images/doctor_booking.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 10),
                Expanded(
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
                        '${_currentPost.author.specialty ?? "Doctor"} • ${_currentPost.timeAgo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
                  '${_currentPost.likesCount} ${_currentPost.likesCount == 1 ? 'like' : 'likes'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentPost.commentsCount} ${_currentPost.commentsCount == 1 ? 'comment' : 'comments'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_currentPost.sharesCount} ${_currentPost.sharesCount == 1 ? 'share' : 'shares'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
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
                label: 'Like',
                color: _currentPost.isLiked ? Colors.red : Colors.grey,
                onTap: _toggleLike,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                color: Colors.grey,
                onTap: _showComments,
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.grey,
                onTap: _showShareOptions,
              ),
            ],
          ),
        ],
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

  // ✅ UPDATED: Video player with thumbnail and mute button
  Widget _buildVideoPlayerWithThumbnail(PostMedia video) {
    if (!_isVideoInitialized || _videoController == null) {
      return Stack(
        children: [
          // Show thumbnail while loading
          if (video.thumbnail != null)
            Image.network(
              video.thumbnail!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            )
          else
            Container(
              height: 250,
              color: Colors.grey[300],
            ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
        
        // Play/Pause button
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
                      color: Colors.black.withOpacity(0.5),
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
        
        // ✅ Mute/Unmute button (top right)
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
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
    return ClipRRect(
      child: Image.network(
        image.url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, size: 50),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMultipleImages(List<PostMedia> images) {
    if (images.length == 2) {
      return Row(
        children: images
            .map((img) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: Image.network(
                      img.url,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ))
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
              Image.network(
                images[index].url,
                fit: BoxFit.cover,
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
        return Image.network(
          images[index].url,
          fit: BoxFit.cover,
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
  final VoidCallback? onCommentAdded; // ✅ Added callback

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
      print('❌ Error loading comments: $e');
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
        
        // ✅ Notify parent to update count
        widget.onCommentAdded?.call();
        
        await _loadComments();
      }
    } catch (e) {
      print('❌ Error submitting comment: $e');
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
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
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
                      ? const Center(child: Text('No comments yet'))
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
                                            'assets/images/doctor_booking.png')
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

            // ✅ FIXED: Input box with proper padding and rounded button
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
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
                    // ✅ FIXED: Round send button
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
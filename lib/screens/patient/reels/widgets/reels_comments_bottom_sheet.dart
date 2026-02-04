import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';

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
                            author?['fullName'] ??
                                AppLocalizations.of(context)!.unknown,
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
    if (dateStr == null) return AppLocalizations.of(context)!.justNow;

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
        return AppLocalizations.of(context)!.justNow;
      }
    } catch (e) {
      return AppLocalizations.of(context)!.justNow;
    }
  }
}

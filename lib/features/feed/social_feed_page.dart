import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/design_system/design_constants.dart';
import '../../shared/models/post.dart';
import '../../services/social_feed_service.dart';
import 'create_post_dialog.dart';

/// Social Feed Page
/// Displays a scrollable feed of posts from the community
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final SocialFeedService _feedService = SocialFeedService.instance;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<Post>>? _feedSubscription;

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    _loadFeed();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFeed() {
    _feedSubscription?.cancel();
    _feedSubscription = _feedService.getGlobalFeedStream(limit: 50).listen(
      (posts) {
        if (mounted) {
          setState(() {
            _posts = posts;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('âŒ [Feed] Error loading feed: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _refreshFeed() async {
    _loadFeed();
  }

  Future<void> _toggleLike(Post post) async {
    await _feedService.toggleLike(post.id, _currentUserId!);
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CreatePostDialog(userId: _currentUserId!),
    );
  }

  void _showComments(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surfaceDefault,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CommentsSheet(post: post, userId: _currentUserId!),
    );
  }

  void _showTipDialog(Post post) {
    if (_currentUserId! == post.userId) return;
    showDialog(
      context: context,
      builder: (ctx) => _TipDialog(
        post: post,
        fromUserId: _currentUserId!,
        feedService: _feedService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.surfaceDefault,
        title: const Text(
          'FEED',
          style: TextStyle(
            color: DesignColors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DesignColors.accent),
            )
          : RefreshIndicator(
              onRefresh: _refreshFeed,
              color: DesignColors.accent,
              child: _posts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _posts.length,
                      itemBuilder: (ctx, index) => _PostCard(
                        post: _posts[index],
                        currentUserId: _currentUserId,
                        onLike: () => _toggleLike(_posts[index]),
                        onComment: () => _showComments(_posts[index]),
                        onTip: () => _showTipDialog(_posts[index]),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: DesignColors.accent,
        child: const Icon(Icons.add, color: DesignColors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feed_outlined,
            size: 80,
            color: DesignColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              color: DesignColors.textGray.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(
              color: DesignColors.textGray.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// POST CARD WIDGET
// ============================================================

class _PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onTip;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    required this.onTip,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = currentUserId != null && post.isLikedBy(currentUserId!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: DesignColors.accent,
                  backgroundImage: post.userAvatar.isNotEmpty
                      ? NetworkImage(post.userAvatar)
                      : null,
                  child: post.userAvatar.isEmpty
                      ? Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: DesignColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          color: DesignColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: DesignColors.textGray.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.type == PostType.roomShare)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.live_tv,
                          size: 14,
                          color: DesignColors.secondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: DesignColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.content,
              style: const TextStyle(
                color: DesignColors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),

          // Image (if any)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 200,
                    color: DesignColors.surfaceDefault,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: DesignColors.textGray,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  color: isLiked ? DesignColors.error : DesignColors.textGray,
                  onTap: onLike,
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentCount}',
                  color: DesignColors.textGray,
                  onTap: onComment,
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  icon: Icons.monetization_on_outlined,
                  label: post.tipCount > 0 ? '${post.tipCount}' : 'Tip',
                  color: DesignColors.gold,
                  onTap: onTip,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  color: DesignColors.textGray,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
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
    );
  }
}

// ============================================================
// COMMENTS SHEET
// ============================================================

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final String? userId;

  const _CommentsSheet({required this.post, required this.userId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final SocialFeedService _feedService = SocialFeedService.instance;
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    await _feedService.addComment(
      postId: widget.post.id,
      userId: widget.userId!,
      content: content,
    );

    _commentController.clear();
    setState(() => _isSubmitting = false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DesignColors.divider),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: DesignColors.textGray),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _feedService.getCommentsStream(widget.post.id),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: DesignColors.accent),
                  );
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: DesignColors.textGray.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (ctx, i) => _CommentTile(comment: comments[i]),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: DesignColors.surfaceLight,
              border: Border(
                top: BorderSide(color: DesignColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: DesignColors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: DesignColors.textGray.withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: DesignColors.surfaceDefault,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignColors.accent,
                          ),
                        )
                      : const Icon(Icons.send, color: DesignColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignColors.accent,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: DesignColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: DesignColors.textGray.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: DesignColors.textLightGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TIP DIALOG
// ============================================================

class _TipDialog extends StatefulWidget {
  final Post post;
  final String fromUserId;
  final SocialFeedService feedService;

  const _TipDialog({
    required this.post,
    required this.fromUserId,
    required this.feedService,
  });

  @override
  State<_TipDialog> createState() => _TipDialogState();
}

class _TipDialogState extends State<_TipDialog> {
  int _selectedAmount = 10;
  bool _isSending = false;

  final List<int> _tipAmounts = [5, 10, 25, 50, 100];

  Future<void> _sendTip() async {
    setState(() => _isSending = true);

    final success = await widget.feedService.tipPost(
      postId: widget.post.id,
      fromUserId: widget.fromUserId,
      coinAmount: _selectedAmount,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Sent $_selectedAmount coins to ${widget.post.userName}!'
                : 'Failed to send tip. Check your balance.',
          ),
          backgroundColor:
              success ? DesignColors.success : DesignColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              color: DesignColors.gold,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Tip ${widget.post.userName}',
              style: const TextStyle(
                color: DesignColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tipAmounts.map((amount) {
                final isSelected = amount == _selectedAmount;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAmount = amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignColors.gold
                          : DesignColors.surfaceDefault,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? DesignColors.gold
                            : DesignColors.divider,
                      ),
                    ),
                    child: Text(
                      '$amount',
                      style: TextStyle(
                        color: isSelected
                            ? DesignColors.surfaceDefault
                            : DesignColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: DesignColors.textGray),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendTip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignColors.gold,
                    foregroundColor: DesignColors.surfaceDefault,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Send $_selectedAmount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _postDocProvider =
    StreamProvider.family<PostModel?, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .snapshots()
      .map((doc) =>
          doc.exists ? PostModel.fromDoc(doc.id, doc.data()!) : null);
});

class _Comment {
  const _Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime createdAt;

  factory _Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return _Comment(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? 'User',
      authorAvatarUrl: d['authorAvatarUrl'] as String?,
      text: d['text'] as String? ?? '',
      createdAt: _parseTs(d['createdAt']),
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }
}

final _commentsProvider =
    StreamProvider.family<List<_Comment>, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(_Comment.fromDoc).toList());
});

// ── Screen ───────────────────────────────────────────────────────────────────

class PostCommentsScreen extends ConsumerStatefulWidget {
  const PostCommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostCommentsScreen> createState() =>
      _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  late final TextEditingController _ctrl;
  late final ScrollController _scroll;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _submitting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final now = FieldValue.serverTimestamp();
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);

      await postRef.collection('comments').add({
        'authorId': user.uid,
        'authorName': user.displayName ?? 'User',
        'authorAvatarUrl': user.photoURL,
        'text': text,
        'createdAt': now,
      });

      _ctrl.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(_postDocProvider(widget.postId));
    final commentsAsync = ref.watch(_commentsProvider(widget.postId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          // Post preview
          postAsync.when(
            data: (post) => post == null
                ? const SizedBox.shrink()
                : PostCard(
                    post: post,
                    currentUserId: currentUser?.uid ?? '',
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          // Comment list
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet.\nBe the first to comment!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  itemCount: comments.length,
                  itemBuilder: (ctx, i) => _CommentTile(comment: comments[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading comments: $e')),
            ),
          ),
          // Input bar
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 12,
                right: 12,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _submitting
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final _Comment comment;

  @override
  Widget build(BuildContext context) {
    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.authorAvatarUrl != null
                ? NetworkImage(comment.authorAvatarUrl!)
                : null,
            child:
                comment.authorAvatarUrl == null ? Text(initial) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(comment.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

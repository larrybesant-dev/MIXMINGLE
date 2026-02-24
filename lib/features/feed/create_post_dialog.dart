import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';
import '../../services/social_feed_service.dart';
import '../../shared/models/post.dart';

/// Dialog for creating a new post
class CreatePostDialog extends StatefulWidget {
  final String userId;

  const CreatePostDialog({super.key, required this.userId});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final SocialFeedService _feedService = SocialFeedService.instance;

  PostType _selectedType = PostType.text;
  bool _isSubmitting = false;

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something'),
          backgroundColor: DesignColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final postId = await _feedService.createPost(
      userId: widget.userId,
      content: content,
      type: _selectedType,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(postId != null ? 'Post created!' : 'Failed to create post'),
          backgroundColor: postId != null ? DesignColors.success : DesignColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Post',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: DesignColors.textGray),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content input
            TextField(
              controller: _contentController,
              style: const TextStyle(color: DesignColors.white),
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  color: DesignColors.textGray.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignColors.accent),
                ),
                filled: true,
                fillColor: DesignColors.surfaceDefault,
                counterStyle: TextStyle(
                  color: DesignColors.textGray.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Post type selector
            Row(
              children: [
                _TypeChip(
                  icon: Icons.text_fields,
                  label: 'Text',
                  isSelected: _selectedType == PostType.text,
                  onTap: () => setState(() => _selectedType = PostType.text),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  icon: Icons.emoji_events,
                  label: 'Achievement',
                  isSelected: _selectedType == PostType.achievement,
                  onTap: () => setState(() => _selectedType = PostType.achievement),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignColors.accent,
                  foregroundColor: DesignColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignColors.white,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DesignColors.accent : DesignColors.surfaceDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DesignColors.accent : DesignColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? DesignColors.white : DesignColors.textGray,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? DesignColors.white : DesignColors.textGray,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

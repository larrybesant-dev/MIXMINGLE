import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';
import '../../services/social/social_feed_service.dart';
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
  final TextEditingController _imageUrlController = TextEditingController();
  final SocialFeedService _feedService = SocialFeedService.instance;

  PostType _selectedType = PostType.text;
  bool _isSubmitting = false;
  bool _imageUrlValid = false;

  void _onImageUrlChanged(String url) {
    final trimmed = url.trim();
    setState(() {
      _imageUrlValid = trimmed.isNotEmpty &&
          (trimmed.startsWith('http://') || trimmed.startsWith('https://'));
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && !_imageUrlValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a caption or paste an image URL'),
          backgroundColor: DesignColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final imageUrl = _selectedType == PostType.image && _imageUrlValid
        ? _imageUrlController.text.trim()
        : null;

    final postId = await _feedService.createPost(
      userId: widget.userId,
      content: content,
      type: _selectedType,
      imageUrl: imageUrl,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(postId != null ? 'Post shared!' : 'Failed to post'),
          backgroundColor:
              postId != null ? DesignColors.success : DesignColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
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
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  isSelected: _selectedType == PostType.image,
                  onTap: () => setState(() => _selectedType = PostType.image),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  icon: Icons.emoji_events,
                  label: 'Achievement',
                  isSelected: _selectedType == PostType.achievement,
                  onTap: () =>
                      setState(() => _selectedType = PostType.achievement),
                ),
              ],
            ),

            // Image URL field (only shown for photo posts)
            if (_selectedType == PostType.image) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _imageUrlController,
                style: const TextStyle(
                    color: DesignColors.white, fontSize: 13),
                onChanged: _onImageUrlChanged,
                decoration: InputDecoration(
                  hintText: 'Paste image URL (https://...)',
                  hintStyle: TextStyle(
                      color: DesignColors.textGray.withValues(alpha: 0.5),
                      fontSize: 13),
                  prefixIcon: const Icon(Icons.link,
                      color: DesignColors.accent, size: 18),
                  suffixIcon: _imageUrlValid
                      ? const Icon(Icons.check_circle,
                          color: DesignColors.success, size: 18)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DesignColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DesignColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DesignColors.accent),
                  ),
                  filled: true,
                  fillColor: DesignColors.surfaceDefault,
                ),
              ),
              // Image preview
              if (_imageUrlValid) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _imageUrlController.text.trim(),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceDefault,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Could not load image preview',
                          style: TextStyle(
                              color: DesignColors.textGray,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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

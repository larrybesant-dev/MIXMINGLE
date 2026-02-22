/// Beta Feedback Form
///
/// A comprehensive feedback form for beta testers with
/// screenshot attachment, categorization, and priority selection.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'closed_beta_service.dart';
import 'feedback_service.dart';

/// Beta feedback form widget
class BetaFeedbackForm extends StatefulWidget {
  final String userId;
  final String? cohortId;
  final String? updateId;
  final String? screenName;
  final VoidCallback? onSubmitted;

  const BetaFeedbackForm({
    super.key,
    required this.userId,
    this.cohortId,
    this.updateId,
    this.screenName,
    this.onSubmitted,
  });

  @override
  State<BetaFeedbackForm> createState() => _BetaFeedbackFormState();
}

class _BetaFeedbackFormState extends State<BetaFeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final ClosedBetaService _betaService = ClosedBetaService.instance;
  final ImagePicker _picker = ImagePicker();

  FeedbackCategory _selectedCategory = FeedbackCategory.suggestion;
  FeedbackPriority _selectedPriority = FeedbackPriority.medium;
  final List<XFile> _attachments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildMessageField(),
              const SizedBox(height: 16),
              _buildAttachmentSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.feedback_outlined,
            color: Color(0xFF10B981),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beta Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Help us improve Mix & Mingle',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: isSelected ? Colors.white : _getCategoryColor(category),
                  ),
                  const SizedBox(width: 4),
                  Text(_getCategoryLabel(category)),
                ],
              ),
              selected: isSelected,
              selectedColor: _getCategoryColor(category),
              backgroundColor: _getCategoryColor(category).withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _getCategoryColor(category),
                fontWeight: FontWeight.w500,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: FeedbackPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PriorityButton(
                  priority: priority,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedPriority = priority),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Feedback',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: _getPlaceholder(),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your feedback';
            }
            if (value.trim().length < 10) {
              return 'Please provide more details (at least 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Screenshots (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            TextButton.icon(
              onPressed: _attachments.length < 3 ? _attachScreenshot : null,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                return _AttachmentThumbnail(
                  file: _attachments[index],
                  onRemove: () {
                    setState(() => _attachments.removeAt(index));
                  },
                );
              },
            ),
          ),
        ] else
          Container(
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: InkWell(
              onTap: _attachScreenshot,
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Tap to add screenshot',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getPlaceholder() {
    switch (_selectedCategory) {
      case FeedbackCategory.bug:
        return 'Describe the bug: What happened? What did you expect? Steps to reproduce...';
      case FeedbackCategory.featureRequest:
        return 'Describe the feature you\'d like to see...';
      case FeedbackCategory.usability:
        return 'What was confusing or difficult to use?';
      case FeedbackCategory.performance:
        return 'Describe the performance issue: slow loading, crashes, lag...';
      case FeedbackCategory.suggestion:
        return 'Share your ideas and suggestions...';
      case FeedbackCategory.other:
        return 'Tell us what\'s on your mind...';
      default:
        return 'Your feedback...';
    }
  }

  IconData _getCategoryIcon(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bug:
        return Icons.bug_report;
      case FeedbackCategory.featureRequest:
        return Icons.lightbulb_outline;
      case FeedbackCategory.usability:
        return Icons.touch_app_outlined;
      case FeedbackCategory.performance:
        return Icons.speed;
      case FeedbackCategory.suggestion:
        return Icons.edit_note;
      case FeedbackCategory.other:
        return Icons.more_horiz;
      default:
        return Icons.feedback;
    }
  }

  Color _getCategoryColor(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bug:
        return Colors.red;
      case FeedbackCategory.featureRequest:
        return Colors.purple;
      case FeedbackCategory.usability:
        return Colors.blue;
      case FeedbackCategory.performance:
        return Colors.orange;
      case FeedbackCategory.suggestion:
        return const Color(0xFF10B981);
      case FeedbackCategory.other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bug:
        return 'Bug';
      case FeedbackCategory.featureRequest:
        return 'Feature';
      case FeedbackCategory.usability:
        return 'Usability';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.suggestion:
        return 'Suggestion';
      case FeedbackCategory.other:
        return 'Other';
      default:
        return category.name;
    }
  }

  Future<void> _attachScreenshot() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && _attachments.length < 3) {
        setState(() => _attachments.add(image));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to attach image')),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // In a real app, would upload attachments first
      final attachmentUrls = <String>[];
      // for (final file in _attachments) {
      //   final url = await uploadService.upload(file);
      //   attachmentUrls.add(url);
      // }

      final result = await _betaService.collectBetaFeedback(
        userId: widget.userId,
        message: _messageController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        cohortId: widget.cohortId,
        updateId: widget.updateId,
        screenName: widget.screenName,
        attachmentUrls: attachmentUrls.isNotEmpty ? attachmentUrls : null,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback! ðŸŽ‰'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          // Reset form
          _messageController.clear();
          setState(() {
            _selectedCategory = FeedbackCategory.suggestion;
            _selectedPriority = FeedbackPriority.medium;
            _attachments.clear();
          });

          widget.onSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to submit feedback'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Priority selection button
class _PriorityButton extends StatelessWidget {
  final FeedbackPriority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getIcon(),
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 4),
            Text(
              _getLabel(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    switch (priority) {
      case FeedbackPriority.low:
        return Colors.grey;
      case FeedbackPriority.medium:
        return Colors.blue;
      case FeedbackPriority.high:
        return Colors.orange;
      case FeedbackPriority.critical:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (priority) {
      case FeedbackPriority.low:
        return Icons.keyboard_arrow_down;
      case FeedbackPriority.medium:
        return Icons.remove;
      case FeedbackPriority.high:
        return Icons.keyboard_arrow_up;
      case FeedbackPriority.critical:
        return Icons.priority_high;
    }
  }

  String _getLabel() {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Low';
      case FeedbackPriority.medium:
        return 'Medium';
      case FeedbackPriority.high:
        return 'High';
      case FeedbackPriority.critical:
        return 'Critical';
    }
  }
}

/// Attachment thumbnail widget
class _AttachmentThumbnail extends StatefulWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _AttachmentThumbnail({
    required this.file,
    required this.onRemove,
  });

  @override
  State<_AttachmentThumbnail> createState() => _AttachmentThumbnailState();
}

class _AttachmentThumbnailState extends State<_AttachmentThumbnail> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.file.readAsBytes();
    if (mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show beta feedback form as bottom sheet
void showBetaFeedbackSheet(
  BuildContext context, {
  required String userId,
  String? cohortId,
  String? updateId,
  String? screenName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  BetaFeedbackForm(
                    userId: userId,
                    cohortId: cohortId,
                    updateId: updateId,
                    screenName: screenName,
                    onSubmitted: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

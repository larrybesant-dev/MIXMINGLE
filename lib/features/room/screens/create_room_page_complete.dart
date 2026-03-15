import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/room_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/models/room.dart';
import '../../../shared/club_background.dart';
import '../../../shared/glow_text.dart';
import '../../../shared/neon_button.dart';
import '../room_access_wrapper.dart';

/// Complete Create Room Page
class CreateRoomPageComplete extends ConsumerStatefulWidget {
  const CreateRoomPageComplete({super.key});

  @override
  ConsumerState<CreateRoomPageComplete> createState() =>
      _CreateRoomPageCompleteState();
}

class _CreateRoomPageCompleteState
    extends ConsumerState<CreateRoomPageComplete> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  RoomType _roomType = RoomType.video;
  String _selectedCategory = 'Chat';
  bool _isPrivate = false;
  bool _isCreating = false;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) throw Exception('User not authenticated');

      final service = ref.read(roomServiceProvider);
      final room = await service.createVoiceRoom(
        hostId: currentUser.id,
        hostName: currentUser.displayName ?? 'Anonymous',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        privacy: _isPrivate ? 'private' : 'public',
      );

      if (mounted) {
        // Navigate to the newly created room
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RoomAccessWrapper(
              room: room,
              userId: currentUser.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(roomCategoriesProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GlowText(
            text: 'Create Room',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            glowColor: Color(0xFFFF4C4C),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                _buildTextField(
                  controller: _titleController,
                  label: 'Room Title',
                  hint: 'Give your room a catchy name',
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'What is your room about?',
                  maxLines: 4,
                  maxLength: 200,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Room Type
                Text(
                  'Room Type',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoomTypeOption(
                        icon: Icons.videocam,
                        label: 'Video',
                        type: RoomType.video,
                        isSelected: _roomType == RoomType.video,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoomTypeOption(
                        icon: Icons.mic,
                        label: 'Voice',
                        type: RoomType.voice,
                        isSelected: _roomType == RoomType.voice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoomTypeOption(
                        icon: Icons.chat,
                        label: 'Text',
                        type: RoomType.text,
                        isSelected: _roomType == RoomType.text,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Category
                Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E2F),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tags
                Text(
                  'Tags (optional, max 5)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _tagController,
                        label: '',
                        hint: 'Add a tag',
                        maxLength: 20,
                        showCounter: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _tags.length < 5 ? _addTag : null,
                      icon: const Icon(Icons.add_circle),
                      color: _tags.length < 5
                          ? const Color(0xFFFF4C4C)
                          : Colors.grey,
                      iconSize: 36,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor:
                            const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                        deleteIconColor: Colors.white,
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Privacy Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Private Room',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Only people with the link can join',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    value: _isPrivate,
                    onChanged: (value) => setState(() => _isPrivate = value),
                    activeThumbColor: const Color(0xFFFF4C4C),
                  ),
                ),

                const SizedBox(height: 32),

                // Create Button
                NeonButton(
                  onPressed: _isCreating ? null : _createRoom,
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: showCounter ? maxLength : null,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomTypeOption({
    required IconData icon,
    required String label,
    required RoomType type,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _roomType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF4C4C), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4C4C)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

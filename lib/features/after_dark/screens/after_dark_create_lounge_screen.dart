import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/room_service.dart';
import '../theme/after_dark_theme.dart';

enum _Privacy { public, friends, private }

class AfterDarkCreateLoungeScreen extends ConsumerStatefulWidget {
  const AfterDarkCreateLoungeScreen({super.key});

  @override
  ConsumerState<AfterDarkCreateLoungeScreen> createState() =>
      _AfterDarkCreateLoungeScreenState();
}

class _AfterDarkCreateLoungeScreenState
    extends ConsumerState<AfterDarkCreateLoungeScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();

  _Privacy _privacy       = _Privacy.public;
  String?  _category;
  String?  _thumbnailUrl;
  bool     _videoEnabled  = false;
  bool     _creating      = false;
  bool     _uploadingThumbnail = false;

  static const List<({String label, String emoji})> _categories = [
    (label: 'Romance',  emoji: '💋'),
    (label: 'Roleplay', emoji: '🎭'),
    (label: 'Chat',     emoji: '💬'),
    (label: 'Couples',  emoji: '💑'),
    (label: 'Dating',   emoji: '❤️'),
    (label: 'Party',    emoji: '🥂'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_uploadingThumbnail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the lounge logo to finish uploading.')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.go('/login');
      return;
    }
    setState(() => _creating = true);
    try {
      final svc = ref.read(roomServiceProvider);
      final roomId = await svc.createRoom(
        hostId:   uid,
        name:     _titleCtrl.text.trim(),
        category: _category?.toLowerCase(),
        isLive:   true,
        isAdult:  true,
        thumbnailUrl: _thumbnailUrl,
      );
      if (mounted) context.go('/room/$roomId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create lounge: $e'),
              backgroundColor: EmberDark.error),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.go('/login');
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingThumbnail = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final ref = FirebaseStorage.instance.ref(
        'rooms/$uid/${DateTime.now().millisecondsSinceEpoch}_after_dark_logo.$ext',
      );
      final snap = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final url = await snap.ref.getDownloadURL();
      if (!mounted) return;
      setState(() => _thumbnailUrl = url);
    } catch (e, st) {
      developer.log(
        'After Dark lounge logo upload failed',
        name: 'AfterDarkCreateLoungeScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logo upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingThumbnail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberDark.surface,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EmberDark.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildHeroBadge(),
                          const SizedBox(height: 28),
                          _sectionLabel('Lounge Title'),
                          const SizedBox(height: 10),
                          _buildTitleInput(),
                          const SizedBox(height: 24),
                          _sectionLabel('Description (optional)'),
                          const SizedBox(height: 10),
                          _buildDescInput(),
                          const SizedBox(height: 24),
                          _sectionLabel('Lounge Logo (optional)'),
                          const SizedBox(height: 10),
                          _buildLogoPicker(),
                          const SizedBox(height: 24),
                          _sectionLabel('Category'),
                          const SizedBox(height: 10),
                          _buildCategories(),
                          const SizedBox(height: 24),
                          _sectionLabel('Privacy'),
                          const SizedBox(height: 10),
                          _buildPrivacyOptions(),
                          const SizedBox(height: 24),
                          _buildVideoToggle(),
                          const SizedBox(height: 24),
                          _buildAdultBadge(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStartButton(),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EmberDark.onSurfaceVariant, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Create Lounge',
              style: TextStyle(
                color: EmberDark.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EmberDark.primaryDim.withValues(alpha: 0.25),
            EmberDark.surfaceHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: EmberDark.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: EmberDark.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This lounge is for 18+ audiences only. '
              'It will appear exclusively in After Dark.',
              style: TextStyle(
                color: EmberDark.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleCtrl,
      style: const TextStyle(color: EmberDark.onSurface),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Enter a lounge title' : null,
      decoration: _inputDeco(
        hint: 'e.g. Late Night Vibes…',
        icon: Icons.mic_rounded,
      ),
    );
  }

  Widget _buildDescInput() {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 3,
      style: const TextStyle(color: EmberDark.onSurface),
      decoration: _inputDeco(
        hint: 'Tell guests what to expect…',
        icon: Icons.notes_rounded,
        isRound: false,
        radius: 14,
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: EmberDark.surfaceHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: EmberDark.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _uploadingThumbnail
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EmberDark.primary,
                    ),
                  ),
                )
              : (_thumbnailUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      _thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_outlined,
                        color: EmberDark.onSurfaceVariant,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: EmberDark.onSurfaceVariant,
                      size: 28,
                    ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload a group photo or logo for the lounge card.',
                style: TextStyle(color: EmberDark.onSurface, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _uploadingThumbnail ? null : _pickAndUploadLogo,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: Text(_thumbnailUrl == null ? 'Upload Logo' : 'Change Logo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmberDark.surfaceHigh,
                      foregroundColor: EmberDark.onSurface,
                      side: BorderSide(
                        color: EmberDark.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  if (_thumbnailUrl != null)
                    TextButton(
                      onPressed: _uploadingThumbnail
                          ? null
                          : () => setState(() => _thumbnailUrl = null),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((c) {
        final selected = _category == c.label;
        return GestureDetector(
          onTap: () => setState(
              () => _category = selected ? null : c.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? EmberDark.primaryGradient : null,
              color: selected ? null : EmberDark.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? EmberDark.primary
                    : EmberDark.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: EmberDark.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Text(
              '${c.emoji} ${c.label}',
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : EmberDark.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyOptions() {
    return Container(
      decoration: BoxDecoration(
        color: EmberDark.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: EmberDark.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: _Privacy.values.map((p) {
          final (label, subtitle, icon) = switch (p) {
            _Privacy.public =>
              ('Public', 'Any 18+ user can join', Icons.public_rounded),
            _Privacy.friends =>
              ('Friends Only', 'Only your friends can join',
                  Icons.group_rounded),
            _Privacy.private =>
              ('Private', 'Invite-only access',
                  Icons.lock_outline_rounded),
          };
          return RadioListTile<_Privacy>(
            value: p,
            groupValue: _privacy, // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _privacy = v!), // ignore: deprecated_member_use
            title: Text(label,
                style: const TextStyle(color: EmberDark.onSurface)),
            subtitle: Text(subtitle,
                style: const TextStyle(
                    color: EmberDark.onSurfaceVariant, fontSize: 12)),
            secondary:
                Icon(icon, color: EmberDark.onSurfaceVariant, size: 20),
            activeColor: EmberDark.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVideoToggle() {
    return Container(
      decoration: BoxDecoration(
        color: EmberDark.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: EmberDark.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: SwitchListTile(
        value: _videoEnabled,
        onChanged: (v) => setState(() => _videoEnabled = v),
        title: const Text('Video Lounge',
            style: TextStyle(color: EmberDark.onSurface)),
        subtitle: const Text('Enable cameras for all participants',
            style: TextStyle(
                color: EmberDark.onSurfaceVariant, fontSize: 12)),
        secondary: const Icon(Icons.videocam_outlined,
            color: EmberDark.onSurfaceVariant),
        activeThumbColor: EmberDark.primary,
      ),
    );
  }

  Widget _buildAdultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: EmberDark.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: EmberDark.primary.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined,
              color: EmberDark.primary, size: 16),
          SizedBox(width: 8),
          Text('Flagged as 18+ Adult Content',
              style: TextStyle(
                color: EmberDark.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            EmberDark.surface.withValues(alpha: 0),
            EmberDark.surface,
          ],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: _creating
            ? const Center(
                child: CircularProgressIndicator(color: EmberDark.primary))
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: EmberDark.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: EmberDark.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.local_fire_department_rounded,
                      size: 20, color: Colors.white),
                  label: const Text('Start Lounge',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: EmberDark.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.4,
        ),
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    bool isRound = true,
    double radius = 999,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: EmberDark.onSurfaceVariant),
      filled: true,
      fillColor: EmberDark.surfaceHigh,
      prefixIcon: Icon(icon, color: EmberDark.onSurfaceVariant, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: EmberDark.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: EmberDark.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: EmberDark.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: EmberDark.error),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}

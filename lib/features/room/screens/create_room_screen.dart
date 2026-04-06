import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/room_service.dart';

// ── colour aliases ────────────────────────────────────────────────────────────
const _surface        = Color(0xFF0B0E14);
const _surfaceHigh    = Color(0xFF1C2028);
const _surfaceHighest = Color(0xFF22262F);
const _surfaceLow     = Color(0xFF10131A);
const _primary        = Color(0xFFBA9EFF);
const _primaryDim     = Color(0xFF8455EF);
const _secondary      = Color(0xFF00E3FD);
const _onSurface      = Color(0xFFECEDF6);
const _onVariant      = Color(0xFFA9ABB3);
const _ghost          = Color(0x1A73757D);

enum _RoomMode { audio, video }
enum _Privacy { public, friends, private }

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  _RoomMode _mode = _RoomMode.audio;
  _Privacy _privacy = _Privacy.public;
  String? _selectedCategory;
  bool _isCreating = false;

  static const List<String> _categories = [
    'Music', 'Gaming', 'Dating', 'Tech Talk',
    'Wellness', 'Art & Design', 'Education', 'Chill',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startRoom() async {
    if (_formKey.currentState?.validate() != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final roomService = ref.read(roomServiceProvider);
      final roomId = await roomService.createRoom(
        hostId: uid,
        name: _titleController.text.trim(),
        category: _selectedCategory?.toLowerCase(),
        isLive: true,
      );
      if (mounted) context.go('/room/$roomId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start room: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFFF6E84),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Ambient blob
          Positioned(
            top: -80, right: -80,
            child: _ambientBlob(_primary.withAlpha(20), 280),
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
                          const SizedBox(height: 8),
                          _buildTitle(),
                          const SizedBox(height: 32),
                          _sectionLabel('Room Title'),
                          const SizedBox(height: 10),
                          _buildTitleInput(),
                          const SizedBox(height: 28),
                          _sectionLabel('Select Mode'),
                          const SizedBox(height: 10),
                          _buildModeToggle(),
                          const SizedBox(height: 28),
                          _sectionLabel('Privacy Settings'),
                          const SizedBox(height: 10),
                          _buildPrivacyOptions(),
                          const SizedBox(height: 28),
                          _sectionLabel('Category'),
                          const SizedBox(height: 10),
                          _buildCategoryChips(),
                          const SizedBox(height: 28),
                          _buildPreviewCard(),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Start button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildStartButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: _ghost),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Text('MIX', style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: _onSurface, fontStyle: FontStyle.italic,
                  letterSpacing: -1)),
              Text('Vy', style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: _primary, fontStyle: FontStyle.italic,
                  letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start a Room', style: GoogleFonts.inter(
            fontSize: 30, fontWeight: FontWeight.w800,
            color: _onSurface, letterSpacing: -1)),
        const SizedBox(height: 6),
        Text(
          'Broadcast your pulse to the world or keep it intimate.',
          style: GoogleFonts.inter(fontSize: 14, color: _onVariant),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: _onVariant, letterSpacing: 0.5));
  }

  Widget _buildTitleInput() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ghost),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: _titleController,
        style: GoogleFonts.inter(fontSize: 16, color: _onSurface),
        decoration: InputDecoration(
          hintText: 'e.g. Late Night Music Session',
          hintStyle: GoogleFonts.inter(fontSize: 16, color: _onVariant),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Please enter a room title';
          if (v.trim().length < 3) return 'Title must be at least 3 characters';
          return null;
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(child: _modeTile(_RoomMode.audio, Icons.mic_rounded, 'Audio Room',
            'Voice broadcast')),
        const SizedBox(width: 12),
        Expanded(child: _modeTile(_RoomMode.video, Icons.videocam_rounded, 'Video Room',
            'Camera broadcast')),
      ],
    );
  }

  Widget _modeTile(_RoomMode mode, IconData icon, String label, String sub) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_primary, _primaryDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: selected ? null : _surfaceHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : _ghost,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? _surface : _primary, size: 28),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: selected ? _surface : _onSurface)),
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.inter(
                fontSize: 12, color: selected ? _surface.withAlpha(180) : _onVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOptions() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ghost),
      ),
      child: Column(
        children: [
          _privacyTile(_Privacy.public, Icons.public_rounded, 'Public',
              'Anyone can join'),
          Divider(height: 1, color: _ghost),
          _privacyTile(_Privacy.friends, Icons.group_rounded, 'Friends Only',
              'Only your friends can join'),
          Divider(height: 1, color: _ghost),
          _privacyTile(_Privacy.private, Icons.lock_rounded, 'Private',
              'Invite only'),
        ],
      ),
    );
  }

  Widget _privacyTile(_Privacy privacy, IconData icon, String label, String sub) {
    final selected = _privacy == privacy;
    return GestureDetector(
      onTap: () => setState(() => _privacy = privacy),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _primary : _onVariant, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: _onSurface)),
                  Text(sub, style: GoogleFonts.inter(
                      fontSize: 12, color: _onVariant)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primary, _primaryDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: _surface),
              )
            else
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _ghost),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(
              () => _selectedCategory = selected ? null : cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [_primary, _primaryDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: selected ? null : _surfaceHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.transparent : _ghost,
              ),
            ),
            child: Text(cat,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? _surface : _onVariant)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1240), Color(0xFF0B0E14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ghost),
      ),
      child: Stack(
        children: [
          // Overlay gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.transparent, Color(0xCC0B0E14)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
            ),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryDim,
                    border: Border.all(color: _secondary, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _secondary.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titleController.text.isEmpty
                          ? 'Previewing your room'
                          : _titleController.text,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: _onSurface),
                    ),
                    Text(
                      'YOUR PULSE IS READY',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: _secondary, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _surface.withAlpha(230),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: _isCreating
                        ? null
                        : const LinearGradient(
                            colors: [_primary, _primaryDim],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                    color: _isCreating ? _surfaceHighest : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: _isCreating
                        ? null
                        : [
                            BoxShadow(
                                color: _primaryDim.withAlpha(90),
                                blurRadius: 24,
                                offset: const Offset(0, 8)),
                          ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isCreating ? null : _startRoom,
                    borderRadius: BorderRadius.circular(999),
                    child: Center(
                      child: _isCreating
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _surface))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('START ROOM NOW',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _surface,
                                        letterSpacing: 0.5)),
                                const SizedBox(width: 8),
                                const Icon(Icons.play_arrow_rounded,
                                    color: _surface, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By starting a room you agree to our Community Guidelines.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: _onVariant),
          ),
        ],
      ),
    );
  }

  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }
}

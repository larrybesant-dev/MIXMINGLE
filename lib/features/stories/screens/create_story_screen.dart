import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/story_provider.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const CreateStoryScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  late TextEditingController _textController;
  bool _isPosting = false;
  bool _isUploadingMedia = false;
  String? _imageUrl;
  String? _videoUrl;

  static const int _maxPhotoBytes = 20 * 1024 * 1024;
  static const int _maxVideoBytes = 120 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _publishStory() async {
    final content = _textController.text.trim();
    if (content.isEmpty && _imageUrl == null && _videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text, a photo, or a video to post a story.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await ref.read(storyControllerProvider).createStory(
            userId: widget.userId,
            username: widget.username,
            userAvatarUrl: widget.avatarUrl,
            content: content,
            imageUrl: _imageUrl,
            videoUrl: _videoUrl,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story posted! Expires in 24 hours')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting story: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<String> _uploadToStorage({
    required XFile file,
    required String folder,
    required String extension,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes().timeout(const Duration(seconds: 20));
    final maxBytes = contentType.startsWith('video/')
        ? _maxVideoBytes
        : _maxPhotoBytes;
    if (bytes.lengthInBytes > maxBytes) {
      throw Exception(
        contentType.startsWith('video/')
            ? 'Video is too large. Choose one under 120MB.'
            : 'Photo is too large. Choose one under 20MB.',
      );
    }

    final path =
        'users/${widget.userId}/stories/$folder/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    await ref
        .putData(bytes, SettableMetadata(contentType: contentType))
        .timeout(const Duration(seconds: 60));
    return ref.getDownloadURL();
  }

  Future<void> _pickPhoto() async {
    if (_isUploadingMedia || _isPosting) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final imageUrl = await _uploadToStorage(
        file: file,
        folder: 'images',
        extension: 'jpg',
        contentType: 'image/jpeg',
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = imageUrl;
        _videoUrl = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story photo uploaded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isUploadingMedia || _isPosting) return;
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 45),
    );
    if (file == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final videoUrl = await _uploadToStorage(
        file: file,
        folder: 'videos',
        extension: 'mp4',
        contentType: 'video/mp4',
      );
      if (!mounted) return;
      setState(() {
        _videoUrl = videoUrl;
        _imageUrl = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story video uploaded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      onPressed: _isUploadingMedia ? null : _publishStory,
                      child: const Text('Post'),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _textController.text.isEmpty ? 'Your story' : _textController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts (24 hours only)...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isUploadingMedia)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      tooltip: 'Add photo',
                      onPressed: (_isUploadingMedia || _isPosting)
                          ? null
                          : _pickPhoto,
                    ),
                    IconButton(
                      icon: const Icon(Icons.video_camera_back),
                      tooltip: 'Add video',
                      onPressed: (_isUploadingMedia || _isPosting)
                          ? null
                          : _pickVideo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.palette),
                      tooltip: 'Color themes are not enabled in beta',
                      onPressed: null,
                    ),
                  ],
                ),
                if (_imageUrl != null || _videoUrl != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_imageUrl != null)
                        const Chip(
                          avatar: Icon(Icons.image, size: 16),
                          label: Text('Photo attached'),
                        ),
                      if (_videoUrl != null)
                        const Chip(
                          avatar: Icon(Icons.videocam, size: 16),
                          label: Text('Video attached'),
                        ),
                      TextButton.icon(
                        onPressed: _isUploadingMedia
                            ? null
                            : () => setState(() {
                                _imageUrl = null;
                                _videoUrl = null;
                              }),
                        icon: const Icon(Icons.clear),
                        label: const Text('Remove media'),
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
}

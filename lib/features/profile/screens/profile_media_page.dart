// lib/features/profile/screens/profile_media_page.dart
//
// Full-screen media gallery page — photos + videos.
// Owner can add / remove media directly from this page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design_system/design_constants.dart';
import '../../../providers/all_providers.dart';
import '../widgets/media_gallery_widget.dart';

class ProfileMediaPage extends ConsumerWidget {
  final String userId;

  /// When [isOwner] is true, add / remove controls are shown.
  final bool isOwner;

  const ProfileMediaPage({
    super.key,
    required this.userId,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Media',
          style: TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignColors.accent),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: DesignColors.error)),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profile not found',
                  style: TextStyle(color: DesignColors.white)),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MediaGallery(
              photos: profile.photoGallery ?? [],
              videos: profile.videoGallery ?? [],
              isOwner: isOwner,
              onAddPhoto: isOwner ? () => _pickAndUploadPhoto(context, ref) : null,
              onAddVideo: isOwner ? () => _pickAndUploadVideo(context, ref) : null,
              onRemove: isOwner
                  ? (url, isVideo) => _handleRemove(context, ref, url, isVideo)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;
    if (!context.mounted) return;
    try {
      await ref
          .read(profileControllerProvider)
          .uploadGalleryPhoto(xfile, userId);
      if (context.mounted) _showSnack(context, 'Photo uploaded!');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Upload failed: $e', isError: true);
    }
  }

  Future<void> _pickAndUploadVideo(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final xfile = await picker.pickVideo(source: ImageSource.gallery);
    if (xfile == null) return;
    if (!context.mounted) return;
    try {
      await ref
          .read(profileControllerProvider)
          .uploadGalleryVideo(xfile, userId);
      if (context.mounted) _showSnack(context, 'Video uploaded!');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Upload failed: $e', isError: true);
    }
  }

  void _handleRemove(
      BuildContext context, WidgetRef ref, String url, bool isVideo) {
    if (!isVideo) {
      ref.read(profileControllerProvider).deleteGalleryPhoto(url).then((_) {
        if (context.mounted) _showSnack(context, 'Photo removed');
      }).catchError((dynamic e) {
        if (context.mounted) _showSnack(context, 'Remove failed', isError: true);
      });
    }
    // Video removal would follow the same delete pattern once added to ProfileController
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? DesignColors.error : DesignColors.success,
      ),
    );
  }
}

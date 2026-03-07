// lib/features/profile/widgets/media_gallery_widget.dart
//
// MediaGallery — unified grid of profile photos + video thumbnails.
// • 3-column grid
// • Tap photo → full-screen pinch-zoom viewer
// • Tap video → shows play-button overlay, tap navigates (or passes onVideoTap)
// • Owner sees an "Add" cell at position 0

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────

class MediaGallery extends StatelessWidget {
  final List<String> photos;
  final List<String> videos;

  /// If true, shows an "Add photo" + "Add video" cell at the end.
  final bool isOwner;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddVideo;

  /// Called with the URL when currentUser taps remove on a cell.
  final void Function(String url, bool isVideo)? onRemove;

  const MediaGallery({
    super.key,
    required this.photos,
    required this.videos,
    this.isOwner = false,
    this.onAddPhoto,
    this.onAddVideo,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Build the merged item list: photos first, then videos
    final items = [
      ...photos.map((u) => _MediaItem(url: u, isVideo: false)),
      ...videos.map((u) => _MediaItem(url: u, isVideo: true)),
    ];

    final addCellCount = isOwner ? 2 : 0; // "Add Photo" + "Add Video"
    final totalCount = items.length + addCellCount;

    if (totalCount == 0) {
      return _buildEmpty();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1,
      ),
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        // "Add Photo" cell
        if (isOwner && i == totalCount - 2) {
          return _AddCell(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Photo',
            onTap: onAddPhoto,
          );
        }
        // "Add Video" cell
        if (isOwner && i == totalCount - 1) {
          return _AddCell(
            icon: Icons.video_library_outlined,
            label: 'Video',
            onTap: onAddVideo,
          );
        }

        final item = items[i];
        return item.isVideo
            ? _VideoThumbCell(
                url: item.url,
                isOwner: isOwner,
                onRemove: onRemove != null ? () => onRemove!(item.url, true) : null,
              )
            : _PhotoCell(
                url: item.url,
                allPhotos: photos,
                index: i,
                isOwner: isOwner,
                onRemove: onRemove != null ? () => onRemove!(item.url, false) : null,
              );
      },
    );
  }

  Widget _buildEmpty() {
    if (!isOwner) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No photos or videos yet',
            style: TextStyle(
                color: DesignColors.textGray.withValues(alpha: 0.6),
                fontSize: 13),
          ),
        ),
      );
    }
    // Owner empty state — still show add cells
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      children: [
        _AddCell(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Photo',
          onTap: onAddPhoto,
        ),
        _AddCell(
          icon: Icons.video_library_outlined,
          label: 'Video',
          onTap: onAddVideo,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA

class _MediaItem {
  final String url;
  final bool isVideo;
  const _MediaItem({required this.url, required this.isVideo});
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO CELL

class _PhotoCell extends StatelessWidget {
  final String url;
  final List<String> allPhotos;
  final int index;
  final bool isOwner;
  final VoidCallback? onRemove;

  const _PhotoCell({
    required this.url,
    required this.allPhotos,
    required this.index,
    required this.isOwner,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      onLongPress: isOwner && onRemove != null ? _confirmRemove(context) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: DesignColors.surfaceLight,
                child: const Icon(Icons.broken_image,
                    color: DesignColors.textGray, size: 32),
              ),
            ),
          ),
          if (isOwner && onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _confirmRemove(context),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenViewer(photos: allPhotos, startIndex: index),
    );
  }

  VoidCallback _confirmRemove(BuildContext context) => () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: DesignColors.surfaceLight,
            title: const Text('Remove photo?',
                style: TextStyle(color: DesignColors.white)),
            content: const Text('This photo will be removed from your gallery.',
                style: TextStyle(color: DesignColors.textGray)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: DesignColors.textGray)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onRemove?.call();
                },
                child: const Text('Remove',
                    style: TextStyle(color: DesignColors.error)),
              ),
            ],
          ),
        );
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO THUMB CELL

class _VideoThumbCell extends StatelessWidget {
  final String url;
  final bool isOwner;
  final VoidCallback? onRemove;

  const _VideoThumbCell(
      {required this.url, required this.isOwner, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image (URL may be a thumbnail or storage video URL)
          _url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: DesignColors.surfaceDefault,
                    child: const Icon(Icons.videocam,
                        color: DesignColors.textGray, size: 32),
                  ),
                )
              : Container(
                  color: DesignColors.surfaceDefault,
                  child: const Icon(Icons.videocam,
                      color: DesignColors.textGray, size: 32),
                ),
          // Dark scrim
          Positioned.fill(
            child: Container(
                color: Colors.black.withValues(alpha: 0.3)),
          ),
          // Play icon
          Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.black87, size: 22),
            ),
          ),
          // Video label
          const Positioned(
            bottom: 6,
            left: 6,
            child: Text(
              'VIDEO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
          ),
          // Remove button (owner)
          if (isOwner && onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _url => url;
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CELL

class _AddCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _AddCell(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DesignColors.accent.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DesignColors.accent, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: DesignColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN PHOTO VIEWER

class _FullScreenViewer extends StatefulWidget {
  final List<String> photos;
  final int startIndex;

  const _FullScreenViewer(
      {required this.photos, required this.startIndex});

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late int _current;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _current = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => InteractiveViewer(
              child: Image.network(
                widget.photos[i],
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                            color: DesignColors.accent)),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Counter
          if (widget.photos.length > 1)
            Positioned(
              top: 22,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_current + 1} / ${widget.photos.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

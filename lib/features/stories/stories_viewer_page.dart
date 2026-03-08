import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_constants.dart';
import '../../services/social/stories_service.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final storyViewerProvider =
    NotifierProvider.autoDispose<_StoryViewerNotifier, _StoryViewerState>(
  _StoryViewerNotifier.new,
);

class _StoryViewerState {
  final int currentStoryIndex;
  final bool isPaused;
  const _StoryViewerState({this.currentStoryIndex = 0, this.isPaused = false});
  _StoryViewerState copyWith({int? currentStoryIndex, bool? isPaused}) =>
      _StoryViewerState(
        currentStoryIndex: currentStoryIndex ?? this.currentStoryIndex,
        isPaused: isPaused ?? this.isPaused,
      );
}

class _StoryViewerNotifier extends Notifier<_StoryViewerState> {
  @override
  _StoryViewerState build() => const _StoryViewerState();
  void next(int total) {
    if (state.currentStoryIndex < total - 1) {
      state = state.copyWith(currentStoryIndex: state.currentStoryIndex + 1);
    }
  }

  void previous() {
    if (state.currentStoryIndex > 0) {
      state = state.copyWith(currentStoryIndex: state.currentStoryIndex - 1);
    }
  }

  void setPaused(bool v) => state = state.copyWith(isPaused: v);
}

// ── Stories Viewer Page ───────────────────────────────────────────────────────

/// Full-screen story viewer. Accepts a [StoryGroup] as route argument.
class StoriesViewerPage extends ConsumerStatefulWidget {
  final StoryGroup group;

  const StoriesViewerPage({super.key, required this.group});

  @override
  ConsumerState<StoriesViewerPage> createState() => _StoriesViewerPageState();
}

class _StoriesViewerPageState extends ConsumerState<StoriesViewerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressDone);
    _startProgress(0);
  }

  void _startProgress(int index) {
    _progressController.reset();
    final story = widget.group.stories[index];
    StoriesService.instance.markViewed(story.id);
    _progressController.forward();
  }

  void _onProgressDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final notifier = ref.read(storyViewerProvider.notifier);
      final current = ref.read(storyViewerProvider).currentStoryIndex;
      if (current < widget.group.stories.length - 1) {
        notifier.next(widget.group.stories.length);
        _startProgress(current + 1);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressDone);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewerState = ref.watch(storyViewerProvider);
    final index = viewerState.currentStoryIndex.clamp(
        0, widget.group.stories.length - 1);
    final story = widget.group.stories[index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) {
          _progressController.stop();
          ref.read(storyViewerProvider.notifier).setPaused(true);
        },
        onTapUp: (details) {
          ref.read(storyViewerProvider.notifier).setPaused(false);
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            // Tap left — go previous
            if (index > 0) {
              ref.read(storyViewerProvider.notifier).previous();
              _startProgress(index - 1);
            } else {
              Navigator.of(context).pop();
            }
          } else {
            // Tap right — go next
            if (index < widget.group.stories.length - 1) {
              ref.read(storyViewerProvider.notifier).next(widget.group.stories.length);
              _startProgress(index + 1);
            } else {
              Navigator.of(context).pop();
            }
          }
        },
        onLongPressStart: (_) {
          _progressController.stop();
          ref.read(storyViewerProvider.notifier).setPaused(true);
        },
        onLongPressEnd: (_) {
          ref.read(storyViewerProvider.notifier).setPaused(false);
          _progressController.forward();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media
            _buildMedia(story),
            // Gradient overlays
            _buildTopGradient(),
            _buildBottomGradient(),
            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: _buildProgressBars(index),
            ),
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 12,
              right: 12,
              child: _buildHeader(story),
            ),
            // Caption
            if (story.caption != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 32,
                left: 16,
                right: 16,
                child: _buildCaption(story.caption!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(StoryModel story) {
    return Image.network(
      story.mediaUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: DesignColors.background,
        child: const Icon(Icons.broken_image, color: Colors.white54, size: 64),
      ),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white30)),
        );
      },
    );
  }

  Widget _buildTopGradient() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return const Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars(int activeIndex) {
    return Row(
      children: List.generate(widget.group.stories.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: i < activeIndex
                    ? 1.0
                    : i == activeIndex
                        ? _progressController.value
                        : 0.0,
                backgroundColor: Colors.white30,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(StoryModel story) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: DesignColors.surfaceLight,
          backgroundImage: story.userAvatar != null
              ? NetworkImage(story.userAvatar!)
              : null,
          child: story.userAvatar == null
              ? Text(
                  (story.userName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: DesignColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                story.userName ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                _timeAgo(story.createdAt),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildCaption(String caption) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        caption,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

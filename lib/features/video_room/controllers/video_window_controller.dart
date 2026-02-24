import 'package:flutter/material.dart';
import '../../../shared/models/video_tile_model.dart';
import '../../../shared/models/window_state_model.dart';

class VideoWindowController {
  VideoTileModel videoTile;
  WindowStateModel windowState;

  VideoWindowController({
    required this.videoTile,
    required this.windowState,
  });

  // Methods to control the window
  void moveTo(Offset newPosition) {
    windowState = windowState.copyWith(position: newPosition);
  }

  void resizeTo(Size newSize) {
    windowState = windowState.copyWith(size: newSize);
  }

  void changeMode(WindowMode newMode) {
    windowState = windowState.copyWith(mode: newMode);
  }

  void togglePin() {
    videoTile = videoTile.copyWith(
      state: videoTile.state == VideoTileState.pinned
          ? VideoTileState.floating
          : VideoTileState.pinned,
    );
  }

  void minimize() {
    videoTile = videoTile.copyWith(state: VideoTileState.minimized);
    windowState = windowState.copyWith(mode: WindowMode.minimized);
  }

  void maximize() {
    windowState = windowState.copyWith(mode: WindowMode.fullscreen);
  }

  void bringToFront(int newZIndex) {
    windowState = windowState.copyWith(zIndex: newZIndex);
  }

  void snapToEdge(EdgeInsets edges) {
    windowState = windowState.copyWith(isSnapped: true, snapEdges: edges);
  }

  void unsnap() {
    windowState = windowState.copyWith(isSnapped: false, snapEdges: null);
  }

  // Getters
  bool get isPinned => videoTile.state == VideoTileState.pinned;
  bool get isMinimized => videoTile.state == VideoTileState.minimized;
  bool get isFullscreen => windowState.mode == WindowMode.fullscreen;
  bool get isSnapped => windowState.isSnapped;
}

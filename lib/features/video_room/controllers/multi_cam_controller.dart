import 'package:flutter/material.dart';
import 'video_window_controller.dart';
import '../../../shared/models/room_video_state_model.dart';
import '../../../shared/models/video_tile_model.dart';
import '../../../shared/models/window_state_model.dart';

class MultiCamController {
  final RoomVideoStateModel roomState;
  final List<VideoWindowController> windowControllers = [];

  MultiCamController(this.roomState) {
    _initializeControllers();
  }

  void _initializeControllers() {
    windowControllers.clear();
    for (var tile in roomState.videoTiles) {
      final windowState = roomState.windowStates
          .firstWhere((ws) => ws.videoTileId == tile.id);
      windowControllers.add(VideoWindowController(
        videoTile: tile,
        windowState: windowState,
      ));
    }
  }

  // Add a new video window
  void addVideoWindow(VideoTileModel tile, WindowStateModel windowState) {
    windowControllers.add(VideoWindowController(
      videoTile: tile,
      windowState: windowState,
    ));
  }

  // Remove a video window
  void removeVideoWindow(String tileId) {
    windowControllers.removeWhere((wc) => wc.videoTile.id == tileId);
  }

  // Get controller for a specific tile
  VideoWindowController? getController(String tileId) {
    return windowControllers.firstWhere((wc) => wc.videoTile.id == tileId);
  }

  // Arrange windows in grid layout
  void arrangeInGrid(Size containerSize) {
    final count = windowControllers.length;
    if (count == 0) return;

    final cols = (count <= 4) ? 2 : (count <= 9) ? 3 : 4;
    final rows = (count / cols).ceil();

    final tileWidth = containerSize.width / cols;
    final tileHeight = containerSize.height / rows;

    for (int i = 0; i < count; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final position = Offset(col * tileWidth, row * tileHeight);
      final size = Size(tileWidth, tileHeight);

      windowControllers[i].moveTo(position);
      windowControllers[i].resizeTo(size);
      windowControllers[i].changeMode(WindowMode.docked);
    }
  }

  // Handle drag and drop
  void handleDrag(String tileId, Offset delta) {
    final controller = getController(tileId);
    if (controller != null) {
      final newPosition = controller.windowState.position + delta;
      controller.moveTo(newPosition);
      controller.changeMode(WindowMode.floating);
    }
  }

  // Bring window to front
  void bringToFront(String tileId) {
    final maxZ = windowControllers
        .map((wc) => wc.windowState.zIndex)
        .reduce((a, b) => a > b ? a : b);
    final controller = getController(tileId);
    controller?.bringToFront(maxZ + 1);
  }

  // Snap to edges
  void snapToEdges(String tileId, Size screenSize) {
    final controller = getController(tileId);
    if (controller == null) return;

    final pos = controller.windowState.position;
    final size = controller.windowState.size;

    EdgeInsets? edges;
    if (pos.dx <= 10) {
      edges = const EdgeInsets.only(left: 0);
    } else if (pos.dx + size.width >= screenSize.width - 10) {
      edges = const EdgeInsets.only(right: 0);
    }
    if (pos.dy <= 10) {
      edges = (edges ?? EdgeInsets.zero).copyWith(top: 0);
    } else if (pos.dy + size.height >= screenSize.height - 10) {
      edges = (edges ?? EdgeInsets.zero).copyWith(bottom: 0);
    }

    if (edges != null) {
      controller.snapToEdge(edges);
    }
  }

  // Update room state
  RoomVideoStateModel getUpdatedRoomState() {
    final updatedTiles = windowControllers.map((wc) => wc.videoTile).toList();
    final updatedWindows = windowControllers.map((wc) => wc.windowState).toList();

    return roomState.copyWith(
      videoTiles: updatedTiles,
      windowStates: updatedWindows,
    );
  }
}

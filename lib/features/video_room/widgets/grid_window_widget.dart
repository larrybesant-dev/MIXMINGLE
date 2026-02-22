import 'package:flutter/material.dart';
import 'video_tile_widget.dart';
import '../../../controllers/video_window_controller.dart';
import '../../../core/design_system/design_constants.dart';

class GridWindowWidget extends StatelessWidget {
  final List<VideoWindowController> controllers;
  final Size containerSize;
  final Function(String)? onTileTap;
  final Function(String)? onTileDoubleTap;

  const GridWindowWidget({
    super.key,
    required this.controllers,
    required this.containerSize,
    this.onTileTap,
    this.onTileDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize.width,
      height: containerSize.height,
      color: DesignColors.surfaceDark,
      child: Stack(
        children: controllers.map((controller) {
          return VideoTileWidget(
            controller: controller,
            onTap: () => onTileTap?.call(controller.videoTile.id),
            onDoubleTap: () => onTileDoubleTap?.call(controller.videoTile.id),
          );
        }).toList(),
      ),
    );
  }
}

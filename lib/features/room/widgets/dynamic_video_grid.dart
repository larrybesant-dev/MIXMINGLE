import 'package:flutter/material.dart';

/// Video tile data for grid layout
class VideoTile {
  final int uid;
  final Widget view;
  final bool isMuted;
  final bool isSpeaking;
  final String displayName;
  final String? avatarUrl;
  final bool isOnCam;

  const VideoTile({
    required this.uid,
    required this.view,
    required this.isMuted,
    required this.isSpeaking,
    required this.displayName,
    this.avatarUrl,
    this.isOnCam = true,
  });
}

/// Dynamic video grid widget that adapts layout based on participant count
class DynamicVideoGrid extends StatelessWidget {
  final List<VideoTile> tiles;
  final EdgeInsets padding;
  final double spacing;

  const DynamicVideoGrid({
    super.key,
    required this.tiles,
    this.padding = const EdgeInsets.all(8.0),
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No one on camera yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final count = tiles.length;

    return Padding(
      padding: padding,
      child: _buildLayout(count),
    );
  }

  Widget _buildLayout(int count) {
    if (count == 1) {
      return _buildSingleTile(tiles[0]);
    } else if (count == 2) {
      return _buildTwoTiles(tiles);
    } else if (count <= 4) {
      return _buildGrid(tiles, crossAxisCount: 2);
    } else if (count <= 9) {
      return _buildGrid(tiles, crossAxisCount: 3);
    } else if (count <= 16) {
      return _buildGrid(tiles, crossAxisCount: 4);
    } else {
      // For more than 16, use scrollable grid
      return _buildScrollableGrid(tiles, crossAxisCount: 4);
    }
  }

  /// Single tile - full screen
  Widget _buildSingleTile(VideoTile tile) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildTileWithOverlay(tile, large: true),
      ),
    );
  }

  /// Two tiles - side by side or top/bottom based on orientation
  Widget _buildTwoTiles(List<VideoTile> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        if (isLandscape) {
          return Row(
            children: tiles
                .map((tile) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(spacing / 2),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildTileWithOverlay(tile),
                        ),
                      ),
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: tiles
                .map((tile) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(spacing / 2),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildTileWithOverlay(tile),
                        ),
                      ),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  /// Grid layout for 3-16 participants
  Widget _buildGrid(List<VideoTile> tiles, {required int crossAxisCount}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemBuilder: (context, index) {
        return _buildTileWithOverlay(tiles[index]);
      },
    );
  }

  /// Scrollable grid layout for 16+ participants
  Widget _buildScrollableGrid(List<VideoTile> tiles, {required int crossAxisCount}) {
    return GridView.builder(
      itemCount: tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemBuilder: (context, index) {
        return _buildTileWithOverlay(tiles[index]);
      },
    );
  }

  /// Build individual tile with name overlay and status indicators
  Widget _buildTileWithOverlay(VideoTile tile, {bool large = false}) {
    return Stack(
      children: [
        // Video view
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.black,
            child: tile.view,
          ),
        ),

        // Speaking indicator (border glow)
        if (tile.isSpeaking)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
              ),
            ),
          ),

        // Name and status overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display name
                Expanded(
                  child: Text(
                    tile.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 16 : 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Mute icon
                if (tile.isMuted)
                  Icon(
                    Icons.mic_off,
                    size: large ? 20 : 14,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        ),

        // Camera off indicator (if not on cam, show avatar or placeholder)
        if (!tile.isOnCam)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tile.avatarUrl != null)
                    CircleAvatar(
                      radius: large ? 48 : 32,
                      backgroundImage: NetworkImage(tile.avatarUrl!),
                    )
                  else
                    Icon(
                      Icons.person,
                      size: large ? 64 : 48,
                      color: Colors.grey.shade600,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    tile.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}



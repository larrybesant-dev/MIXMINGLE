import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_wall_provider.dart';

class CameraWallRemoteTileData {
  const CameraWallRemoteTileData({
    required this.uid,
    required this.label,
    required this.canView,
    required this.isSpeaking,
    this.viewerCount,
  });

  final int uid;
  final String label;
  final bool canView;
  final bool isSpeaking;
  /// Optional viewer count shown as a badge on the tile (null = hidden).
  final int? viewerCount;
}

class CameraWall extends ConsumerWidget {
  const CameraWall({
    super.key,
    required this.roomId,
    required this.localLabel,
    required this.localSpeaking,
    required this.localTile,
    required this.remoteTiles,
    required this.remoteTileBuilder,
    required this.onSubscriptionPlanChanged,
    required this.roomName,
    this.maxMainGridRemoteTiles = 8,
    this.overflowPageSize = 6,
    this.onDetachLocal,
    this.onDetachRemote,
  });

  final String roomId;
  final String localLabel;
  final bool localSpeaking;
  final Widget localTile;
  final List<CameraWallRemoteTileData> remoteTiles;
  final Widget Function(CameraWallRemoteTileData tile) remoteTileBuilder;
  final void Function(Set<int> highQualityUids, Set<int> lowQualityUids)
  onSubscriptionPlanChanged;
  final String roomName;
  final int maxMainGridRemoteTiles;
  final int overflowPageSize;
  /// Called when the user clicks "detach" on the local cam tile.
  final VoidCallback? onDetachLocal;
  /// Called when the user clicks "detach" on a remote cam tile.
  final void Function(CameraWallRemoteTileData tile)? onDetachRemote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        final mainGridRemoteLimit = isDesktop
            ? maxMainGridRemoteTiles + 4
            : maxMainGridRemoteTiles;
        final effectiveOverflowPageSize = isDesktop
            ? overflowPageSize * 2
            : overflowPageSize;

        final viewableRemoteTiles = remoteTiles
            .where((tile) => tile.canView)
            .toList(growable: false);
        final blockedRemoteTiles = remoteTiles
            .where((tile) => !tile.canView)
            .toList(growable: false);
        final mainGridRemoteTiles = viewableRemoteTiles
            .take(mainGridRemoteLimit)
            .toList(growable: false);
        final overflowTiles = <CameraWallRemoteTileData>[
          ...viewableRemoteTiles.skip(mainGridRemoteLimit),
          ...blockedRemoteTiles,
        ];

        final overflowPageCount = overflowTiles.isEmpty
            ? 0
            : ((overflowTiles.length - 1) ~/ effectiveOverflowPageSize) + 1;
        final rawOverflowPage = ref.watch(cameraWallOverflowPageProvider(roomId));
        final overflowPage = overflowPageCount == 0
            ? 0
            : rawOverflowPage.clamp(0, overflowPageCount - 1);
        if (overflowPage != rawOverflowPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(cameraWallOverflowPageProvider(roomId).notifier).state =
                overflowPage;
          });
        }

        final overflowStart = overflowPage * effectiveOverflowPageSize;
        final overflowEnd = overflowPageCount == 0
            ? 0
            : (overflowStart + effectiveOverflowPageSize > overflowTiles.length
                  ? overflowTiles.length
                  : overflowStart + effectiveOverflowPageSize);
        final visibleOverflowTiles = overflowTiles.sublist(
          overflowStart,
          overflowEnd,
        );

        final highQualityUids = mainGridRemoteTiles
            .map((tile) => tile.uid)
            .toSet();
        final lowQualityUids = visibleOverflowTiles
            .where((tile) => tile.canView)
            .map((tile) => tile.uid)
            .toSet();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSubscriptionPlanChanged(highQualityUids, lowQualityUids);
        });

        final mainGridTiles = <Widget>[
          _CameraWallTileFrame(
            label: localLabel,
            speaking: localSpeaking,
            compact: false,
            onDetach: onDetachLocal,
            child: localTile,
          ),
          ...mainGridRemoteTiles.map(
            (tile) => _CameraWallTileFrame(
              label: tile.label,
              speaking: tile.isSpeaking,
              compact: false,
              viewerCount: tile.viewerCount,
              onDetach: onDetachRemote == null
                  ? null
                  : () => onDetachRemote!(tile),
              child: remoteTileBuilder(tile),
            ),
          ),
        ];

        final tileCount = mainGridTiles.length;
        final crossAxisCount = isDesktop
            ? (tileCount <= 1 ? 1 : tileCount <= 4 ? 2 : tileCount <= 9 ? 3 : 4)
            : (tileCount <= 2 ? 1 : tileCount <= 4 ? 2 : 3);
        // Cap the grid height so the cam box stays compact on desktop.
        final availableHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 58.0).clamp(160.0, 1200.0)
            : null;
        final mainGridHeight = isDesktop
            ? (tileCount <= 2
                ? (availableHeight != null ? availableHeight.clamp(160.0, 320.0) : 320.0)
                : tileCount <= 4
                    ? (availableHeight != null ? availableHeight.clamp(160.0, 440.0) : 440.0)
                    : (availableHeight ?? (tileCount <= 8 ? 520.0 : 660.0)))
            : (tileCount <= 1 ? 180.0 : tileCount <= 4 ? 280.0 : 360.0);
        const npSurfaceLow   = Color(0xFF10131A);
        const npSurfaceHigh  = Color(0xFF1C2028);
        const npPrimary      = Color(0xFFBA9EFF);
        const npOnVariant    = Color(0xFFA9ABB3);
        const npGhost        = Color(0x1A73757D);

        return ColoredBox(
          color: npSurfaceLow,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x33BA9EFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: npGhost),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            color: npPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: npSurfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: npGhost),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '${1 + remoteTiles.length} windows',
                          style: const TextStyle(
                            color: npOnVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (overflowPageCount > 1)
                      Text(
                        'Page ${overflowPage + 1} of $overflowPageCount',
                        style: const TextStyle(color: Color(0xFFA9ABB3), fontSize: 12),
                      ),
                    if (overflowTiles.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Previous cam page',
                        visualDensity: VisualDensity.compact,
                        onPressed: overflowPage > 0
                            ? () {
                                ref
                                        .read(
                                          cameraWallOverflowPageProvider(roomId)
                                              .notifier,
                                        )
                                        .state =
                                    overflowPage - 1;
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        tooltip: 'Next cam page',
                        visualDensity: VisualDensity.compact,
                        onPressed: overflowPage < overflowPageCount - 1
                            ? () {
                                ref
                                        .read(
                                          cameraWallOverflowPageProvider(roomId)
                                              .notifier,
                                        )
                                        .state =
                                    overflowPage + 1;
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: mainGridHeight,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 16 / 9,
                                ),
                            itemCount: mainGridTiles.length,
                            itemBuilder: (context, index) => mainGridTiles[index],
                          ),
                        ),
                      ),
                      if (overflowTiles.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 208,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF161A21),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x1A73757D),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Extra Windows',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: (mainGridHeight - 24).clamp(100.0, 1200.0),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            childAspectRatio: 1,
                                          ),
                                      itemCount: visibleOverflowTiles.length,
                                      itemBuilder: (context, index) {
                                        final tile = visibleOverflowTiles[index];
                                        return _CameraWallTileFrame(
                                          label: tile.label,
                                          speaking: tile.isSpeaking,
                                          compact: true,
                                          onDetach: onDetachRemote == null
                                              ? null
                                              : () => onDetachRemote!(tile),
                                          child: remoteTileBuilder(tile),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                else ...[
                  SizedBox(
                    height: mainGridHeight,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 16 / 9,
                      ),
                      itemCount: mainGridTiles.length,
                      itemBuilder: (context, index) => mainGridTiles[index],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (overflowTiles.isNotEmpty)
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: visibleOverflowTiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tile = visibleOverflowTiles[index];
                          return SizedBox(
                            width: 132,
                            child: _CameraWallTileFrame(
                              label: tile.label,
                              speaking: tile.isSpeaking,
                              compact: true,
                              onDetach: onDetachRemote == null
                                  ? null
                                  : () => onDetachRemote!(tile),
                              child: remoteTileBuilder(tile),
                            ),
                          );
                        },
                      ),
                    )
                  else if (remoteTiles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Waiting for others to join video...',
                        style: TextStyle(color: Color(0xFFA9ABB3), fontSize: 13),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CameraWallTileFrame extends StatefulWidget {
  const _CameraWallTileFrame({
    required this.label,
    required this.speaking,
    required this.compact,
    required this.child,
    this.onDetach,
    this.viewerCount,
  });

  final String label;
  final bool speaking;
  final bool compact;
  final Widget child;
  /// If non-null, a pop-out button is shown in the tile header.
  final VoidCallback? onDetach;
  /// If non-null and > 0, a viewer count badge is shown on the tile.
  final int? viewerCount;

  @override
  State<_CameraWallTileFrame> createState() => _CameraWallTileFrameState();
}

class _CameraWallTileFrameState extends State<_CameraWallTileFrame> {

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const npSurfaceContainer = Color(0xFF161A21);
    const npSurfaceHigh      = Color(0xFF1C2028);
    const npSecondary        = Color(0xFF00E3FD); // cyan speaking
    const npOnVariant        = Color(0xFFA9ABB3);

    final radius = widget.compact ? 8.0 : 10.0;
    final borderColor = widget.speaking ? npSecondary : const Color(0x1A73757D);
    final glowShadow = widget.speaking
        ? [BoxShadow(color: npSecondary.withAlpha(60), blurRadius: 8, spreadRadius: 1)]
        : const <BoxShadow>[];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: npSurfaceContainer,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: widget.speaking ? 2 : 1),
          boxShadow: glowShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            children: [
              Container(
                height: widget.compact ? 20 : 24,
                color: npSurfaceHigh,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.speaking ? npSecondary : npOnVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Pop-out button: visible on hover (desktop) or always on mobile
                    if (widget.onDetach != null &&
                        (_hovered || widget.compact))
                      Tooltip(
                        message: 'Detach window',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: widget.onDetach,
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: npOnVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: const Color(0xFF0B0E14),
                      child: widget.child,
                    ),
                    // Viewer count badge (bottom-right corner)
                    if (widget.viewerCount != null && widget.viewerCount! > 0)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility, color: Color(0xFF00E3FD), size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.viewerCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


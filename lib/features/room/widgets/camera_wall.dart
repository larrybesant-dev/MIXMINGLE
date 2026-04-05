import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_wall_provider.dart';

class CameraWallRemoteTileData {
  const CameraWallRemoteTileData({
    required this.uid,
    required this.label,
    required this.canView,
    required this.isSpeaking,
  });

  final int uid;
  final String label;
  final bool canView;
  final bool isSpeaking;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 920;
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
            child: localTile,
          ),
          ...mainGridRemoteTiles.map(
            (tile) => _CameraWallTileFrame(
              label: tile.label,
              speaking: tile.isSpeaking,
              compact: false,
              child: remoteTileBuilder(tile),
            ),
          ),
        ];

        final tileCount = mainGridTiles.length;
        final crossAxisCount = isDesktop
            ? (tileCount <= 4 ? 2 : tileCount <= 9 ? 3 : 4)
            : (tileCount <= 2 ? 1 : tileCount <= 4 ? 2 : 3);
        final mainGridHeight = isDesktop
            ? (tileCount <= 4 ? 300.0 : tileCount <= 8 ? 420.0 : 560.0)
            : (tileCount <= 1 ? 180.0 : tileCount <= 4 ? 280.0 : 360.0);
        final theme = Theme.of(context);
        final panelColor = theme.colorScheme.surfaceContainerHighest;
        final dockColor = theme.colorScheme.surfaceContainer;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      roomName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '${1 + remoteTiles.length} windows',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (overflowPageCount > 1)
                      Text(
                        'Page ${overflowPage + 1} of $overflowPageCount',
                        style: theme.textTheme.bodySmall,
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
                              color: dockColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Extra Windows',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: mainGridHeight - 24,
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
                              child: remoteTileBuilder(tile),
                            ),
                          );
                        },
                      ),
                    )
                  else if (remoteTiles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Waiting for other participants to join video...'),
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

class _CameraWallTileFrame extends StatelessWidget {
  const _CameraWallTileFrame({
    required this.label,
    required this.speaking,
    required this.compact,
    required this.child,
  });

  final String label;
  final bool speaking;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = compact ? 8.0 : 10.0;
    final borderColor = speaking
        ? const Color(0xFF41C56B)
        : theme.colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101316),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: speaking ? 2 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          children: [
            Container(
              height: compact ? 20 : 24,
              color: const Color(0xFF232A31),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: speaking
                          ? const Color(0xFF41C56B)
                          : const Color(0xFF7E8791),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


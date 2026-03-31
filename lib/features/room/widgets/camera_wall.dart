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
  final int maxMainGridRemoteTiles;
  final int overflowPageSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewableRemoteTiles = remoteTiles
        .where((tile) => tile.canView)
        .toList(growable: false);
    final blockedRemoteTiles = remoteTiles
        .where((tile) => !tile.canView)
        .toList(growable: false);
    final mainGridRemoteTiles = viewableRemoteTiles
        .take(maxMainGridRemoteTiles)
        .toList(growable: false);
    final overflowTiles = <CameraWallRemoteTileData>[
      ...viewableRemoteTiles.skip(maxMainGridRemoteTiles),
      ...blockedRemoteTiles,
    ];

    final overflowPageCount = overflowTiles.isEmpty
        ? 0
        : ((overflowTiles.length - 1) ~/ overflowPageSize) + 1;
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

    final overflowStart = overflowPage * overflowPageSize;
    final overflowEnd = overflowPageCount == 0
        ? 0
        : (overflowStart + overflowPageSize > overflowTiles.length
              ? overflowTiles.length
              : overflowStart + overflowPageSize);
    final visibleOverflowTiles = overflowTiles.sublist(overflowStart, overflowEnd);

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
    final crossAxisCount = tileCount <= 2
        ? 1
        : tileCount <= 4
        ? 2
        : 3;
    final mainGridHeight = tileCount <= 1
        ? 180.0
        : tileCount <= 4
        ? 280.0
        : 360.0;

    return Column(
      children: [
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
        if (overflowTiles.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'More cams',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              if (overflowPageCount > 1)
                Text(
                  '${overflowPage + 1}/$overflowPageCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              IconButton(
                tooltip: 'Previous cam page',
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
          ),
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
          ),
        ] else if (remoteTiles.isEmpty)
          const Text('Waiting for other participants to join video...'),
      ],
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
    final radius = compact ? 10.0 : 12.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: speaking ? Colors.green : Colors.transparent,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
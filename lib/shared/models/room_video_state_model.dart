import 'video_tile_model.dart';
import 'window_state_model.dart';
import 'publisher_state_model.dart';

enum RoomVideoLayout { grid, floating, adaptive }

class RoomVideoStateModel {
  final String roomId;
  final List<VideoTileModel> videoTiles;
  final List<WindowStateModel> windowStates;
  final List<PublisherStateModel> publishers;
  final RoomVideoLayout layout;
  final int maxPublishers;
  final bool autoMuteOnJoin;
  final bool autoDisableVideoOnLowBandwidth;
  final DateTime lastUpdated;

  RoomVideoStateModel({
    required this.roomId,
    this.videoTiles = const [],
    this.windowStates = const [],
    this.publishers = const [],
    this.layout = RoomVideoLayout.grid,
    this.maxPublishers = 12,
    this.autoMuteOnJoin = true,
    this.autoDisableVideoOnLowBandwidth = true,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  RoomVideoStateModel copyWith({
    String? roomId,
    List<VideoTileModel>? videoTiles,
    List<WindowStateModel>? windowStates,
    List<PublisherStateModel>? publishers,
    RoomVideoLayout? layout,
    int? maxPublishers,
    bool? autoMuteOnJoin,
    bool? autoDisableVideoOnLowBandwidth,
    DateTime? lastUpdated,
  }) {
    return RoomVideoStateModel(
      roomId: roomId ?? this.roomId,
      videoTiles: videoTiles ?? this.videoTiles,
      windowStates: windowStates ?? this.windowStates,
      publishers: publishers ?? this.publishers,
      layout: layout ?? this.layout,
      maxPublishers: maxPublishers ?? this.maxPublishers,
      autoMuteOnJoin: autoMuteOnJoin ?? this.autoMuteOnJoin,
      autoDisableVideoOnLowBandwidth:
          autoDisableVideoOnLowBandwidth ?? this.autoDisableVideoOnLowBandwidth,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'videoTiles': videoTiles.map((e) => e.toJson()).toList(),
      'windowStates': windowStates.map((e) => e.toJson()).toList(),
      'publishers': publishers.map((e) => e.toJson()).toList(),
      'layout': layout.toString(),
      'maxPublishers': maxPublishers,
      'autoMuteOnJoin': autoMuteOnJoin,
      'autoDisableVideoOnLowBandwidth': autoDisableVideoOnLowBandwidth,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory RoomVideoStateModel.fromJson(Map<String, dynamic> json) {
    return RoomVideoStateModel(
      roomId: json['roomId'],
      videoTiles: (json['videoTiles'] as List<dynamic>?)
              ?.map((e) => VideoTileModel.fromJson(e))
              .toList() ??
          [],
      windowStates: (json['windowStates'] as List<dynamic>?)
              ?.map((e) => WindowStateModel.fromJson(e))
              .toList() ??
          [],
      publishers: (json['publishers'] as List<dynamic>?)
              ?.map((e) => PublisherStateModel.fromJson(e))
              .toList() ??
          [],
      layout: RoomVideoLayout.values.firstWhere(
        (e) => e.toString() == json['layout'],
        orElse: () => RoomVideoLayout.grid,
      ),
      maxPublishers: json['maxPublishers'] ?? 12,
      autoMuteOnJoin: json['autoMuteOnJoin'] ?? true,
      autoDisableVideoOnLowBandwidth:
          json['autoDisableVideoOnLowBandwidth'] ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Helper methods
  VideoTileModel? getVideoTile(String id) {
    return videoTiles.firstWhere((tile) => tile.id == id);
  }

  WindowStateModel? getWindowState(String id) {
    return windowStates.firstWhere((window) => window.id == id);
  }

  PublisherStateModel? getPublisher(String userId) {
    return publishers.firstWhere((pub) => pub.userId == userId);
  }

  int get activePublishers =>
      publishers.where((p) => p.status == PublisherStatus.publishing).length;
}

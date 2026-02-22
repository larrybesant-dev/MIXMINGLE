import 'package:flutter/material.dart';

enum VideoTileState { pinned, floating, minimized, grid }

class VideoTileModel {
  final String id;
  final String userId;
  final String? streamId;
  final Offset position;
  final Size size;
  final VideoTileState state;
  final int zIndex;
  final bool isMuted;
  final bool isVideoEnabled;
  final double resolution; // e.g., 0.5 for half, 1.0 for full

  VideoTileModel({
    required this.id,
    required this.userId,
    this.streamId,
    this.position = Offset.zero,
    this.size = const Size(320, 240),
    this.state = VideoTileState.grid,
    this.zIndex = 0,
    this.isMuted = false,
    this.isVideoEnabled = true,
    this.resolution = 1.0,
  });

  VideoTileModel copyWith({
    String? id,
    String? userId,
    String? streamId,
    Offset? position,
    Size? size,
    VideoTileState? state,
    int? zIndex,
    bool? isMuted,
    bool? isVideoEnabled,
    double? resolution,
  }) {
    return VideoTileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      streamId: streamId ?? this.streamId,
      position: position ?? this.position,
      size: size ?? this.size,
      state: state ?? this.state,
      zIndex: zIndex ?? this.zIndex,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      resolution: resolution ?? this.resolution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'streamId': streamId,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'state': state.toString(),
      'zIndex': zIndex,
      'isMuted': isMuted,
      'isVideoEnabled': isVideoEnabled,
      'resolution': resolution,
    };
  }

  factory VideoTileModel.fromJson(Map<String, dynamic> json) {
    return VideoTileModel(
      id: json['id'],
      userId: json['userId'],
      streamId: json['streamId'],
      position: Offset(json['position']['dx'], json['position']['dy']),
      size: Size(json['size']['width'], json['size']['height']),
      state: VideoTileState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => VideoTileState.grid,
      ),
      zIndex: json['zIndex'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isVideoEnabled: json['isVideoEnabled'] ?? true,
      resolution: json['resolution'] ?? 1.0,
    );
  }
}

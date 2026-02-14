import 'package:flutter/material.dart';

enum WindowMode { floating, docked, fullscreen, minimized }

class WindowStateModel {
  final String id;
  final String videoTileId;
  final WindowMode mode;
  final Offset position;
  final Size size;
  final bool isSnapped;
  final EdgeInsets? snapEdges; // for snapping to screen edges
  final int zIndex;

  WindowStateModel({
    required this.id,
    required this.videoTileId,
    this.mode = WindowMode.floating,
    this.position = Offset.zero,
    this.size = const Size(320, 240),
    this.isSnapped = false,
    this.snapEdges,
    this.zIndex = 0,
  });

  WindowStateModel copyWith({
    String? id,
    String? videoTileId,
    WindowMode? mode,
    Offset? position,
    Size? size,
    bool? isSnapped,
    EdgeInsets? snapEdges,
    int? zIndex,
  }) {
    return WindowStateModel(
      id: id ?? this.id,
      videoTileId: videoTileId ?? this.videoTileId,
      mode: mode ?? this.mode,
      position: position ?? this.position,
      size: size ?? this.size,
      isSnapped: isSnapped ?? this.isSnapped,
      snapEdges: snapEdges ?? this.snapEdges,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoTileId': videoTileId,
      'mode': mode.toString(),
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'isSnapped': isSnapped,
      'snapEdges': snapEdges != null
          ? {
              'left': snapEdges!.left,
              'top': snapEdges!.top,
              'right': snapEdges!.right,
              'bottom': snapEdges!.bottom,
            }
          : null,
    };
  }

  factory WindowStateModel.fromJson(Map<String, dynamic> json) {
    return WindowStateModel(
      id: json['id'],
      videoTileId: json['videoTileId'],
      mode: WindowMode.values.firstWhere(
        (e) => e.toString() == json['mode'],
        orElse: () => WindowMode.floating,
      ),
      position: Offset(json['position']['dx'], json['position']['dy']),
      size: Size(json['size']['width'], json['size']['height']),
      isSnapped: json['isSnapped'] ?? false,
      snapEdges: json['snapEdges'] != null
          ? EdgeInsets.fromLTRB(
              json['snapEdges']['left'],
              json['snapEdges']['top'],
              json['snapEdges']['right'],
              json['snapEdges']['bottom'],
            )
          : null,
    );
  }
}

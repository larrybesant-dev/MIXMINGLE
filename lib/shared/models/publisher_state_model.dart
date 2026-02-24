enum PublisherStatus { idle, publishing, paused, error }

class PublisherStateModel {
  final String userId;
  final String? streamId;
  final PublisherStatus status;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final int bitrate; // in kbps
  final double resolution; // 0.25, 0.5, 1.0
  final int frameRate; // 15, 30, etc.
  final DateTime? lastPublishedAt;
  final String? errorMessage;

  PublisherStateModel({
    required this.userId,
    this.streamId,
    this.status = PublisherStatus.idle,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.bitrate = 512,
    this.resolution = 1.0,
    this.frameRate = 30,
    this.lastPublishedAt,
    this.errorMessage,
  });

  PublisherStateModel copyWith({
    String? userId,
    String? streamId,
    PublisherStatus? status,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    int? bitrate,
    double? resolution,
    int? frameRate,
    DateTime? lastPublishedAt,
    String? errorMessage,
  }) {
    return PublisherStateModel(
      userId: userId ?? this.userId,
      streamId: streamId ?? this.streamId,
      status: status ?? this.status,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      bitrate: bitrate ?? this.bitrate,
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      lastPublishedAt: lastPublishedAt ?? this.lastPublishedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'streamId': streamId,
      'status': status.toString(),
      'isAudioEnabled': isAudioEnabled,
      'isVideoEnabled': isVideoEnabled,
      'bitrate': bitrate,
      'resolution': resolution,
      'frameRate': frameRate,
      'lastPublishedAt': lastPublishedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory PublisherStateModel.fromJson(Map<String, dynamic> json) {
    return PublisherStateModel(
      userId: json['userId'],
      streamId: json['streamId'],
      status: PublisherStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PublisherStatus.idle,
      ),
      isAudioEnabled: json['isAudioEnabled'] ?? true,
      isVideoEnabled: json['isVideoEnabled'] ?? true,
      bitrate: json['bitrate'] ?? 512,
      resolution: json['resolution'] ?? 1.0,
      frameRate: json['frameRate'] ?? 30,
      lastPublishedAt: json['lastPublishedAt'] != null
          ? DateTime.parse(json['lastPublishedAt'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }
}



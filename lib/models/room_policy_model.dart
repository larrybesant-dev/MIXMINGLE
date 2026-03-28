enum MixVyRoomVisibility {
  public,
  private,
  password,
}

enum MixVyRoomRole {
  owner,
  admin,
  moderator,
  vip,
  member,
  banned,
}

enum CamViewPolicy {
  everyone,
  friendsOnly,
  approvedOnly,
  nobody,
}

class RoomPolicyModel {
  const RoomPolicyModel({
    required this.roomId,
    this.visibility = MixVyRoomVisibility.public,
    this.minimumAge = 18,
    this.camLimit = 6,
    this.micLimit = 6,
    this.allowChat = true,
    this.allowGifts = true,
    this.allowMicRequests = true,
    this.allowCamRequests = true,
    this.defaultCamViewPolicy = CamViewPolicy.approvedOnly,
    this.updatedAt,
  });

  final String roomId;
  final MixVyRoomVisibility visibility;
  final int minimumAge;
  final int camLimit;
  final int micLimit;
  final bool allowChat;
  final bool allowGifts;
  final bool allowMicRequests;
  final bool allowCamRequests;
  final CamViewPolicy defaultCamViewPolicy;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'visibility': visibility.name,
      'minimumAge': minimumAge,
      'camLimit': camLimit,
      'micLimit': micLimit,
      'allowChat': allowChat,
      'allowGifts': allowGifts,
      'allowMicRequests': allowMicRequests,
      'allowCamRequests': allowCamRequests,
      'defaultCamViewPolicy': defaultCamViewPolicy.name,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RoomPolicyModel.fromJson(Map<String, dynamic> json) {
    return RoomPolicyModel(
      roomId: json['roomId'] as String? ?? '',
      visibility: MixVyRoomVisibility.values.firstWhere(
        (value) => value.name == json['visibility'],
        orElse: () => MixVyRoomVisibility.public,
      ),
      minimumAge: (json['minimumAge'] as num?)?.toInt() ?? 18,
      camLimit: (json['camLimit'] as num?)?.toInt() ?? 6,
      micLimit: (json['micLimit'] as num?)?.toInt() ?? 6,
      allowChat: json['allowChat'] as bool? ?? true,
      allowGifts: json['allowGifts'] as bool? ?? true,
      allowMicRequests: json['allowMicRequests'] as bool? ?? true,
      allowCamRequests: json['allowCamRequests'] as bool? ?? true,
      defaultCamViewPolicy: CamViewPolicy.values.firstWhere(
        (value) => value.name == json['defaultCamViewPolicy'],
        orElse: () => CamViewPolicy.approvedOnly,
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class CamAccessRequestModel {
  const CamAccessRequestModel({
    required this.id,
    required this.roomId,
    required this.requesterId,
    required this.broadcasterId,
    this.status = 'pending',
    this.decisionScope = 'single_session',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String roomId;
  final String requesterId;
  final String broadcasterId;
  final String status;
  final String decisionScope;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'requesterId': requesterId,
      'broadcasterId': broadcasterId,
      'status': status,
      'decisionScope': decisionScope,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'participantIds': [requesterId, broadcasterId],
    };
  }

  factory CamAccessRequestModel.fromJson(Map<String, dynamic> json) {
    return CamAccessRequestModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      broadcasterId: json['broadcasterId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      decisionScope: json['decisionScope'] as String? ?? 'single_session',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
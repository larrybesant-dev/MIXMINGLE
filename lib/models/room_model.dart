


class RoomModel {
  final String id;
  final String name;
  final String? description;
  final String hostId;
  final bool isLive;
  final String? thumbnailUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // Members
  final List<String> stageUserIds;
  final List<String> audienceUserIds;

  // Metadata
  final int memberCount;
  final String? category;
  final List<String> tags;

  RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.description,
    this.isLive = false,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
    this.stageUserIds = const [],
    this.audienceUserIds = const [],
    this.memberCount = 0,
    this.category,
    this.tags = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Room',
    RoomModel({
      required this.id,
      required this.name,
      required this.hostId,
      this.description,
      this.isLive = false,
      this.thumbnailUrl,
      this.createdAt,
      this.updatedAt,
      this.stageUserIds = const [],
      this.audienceUserIds = const [],
      this.memberCount = 0,
      this.category,
      this.tags = const [],
    });
    return {
      'name': name,
      'description': description,
      'hostId': hostId,
      'isLive': isLive,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'stageUserIds': stageUserIds,
      'audienceUserIds': audienceUserIds,
      'memberCount': memberCount,
      'category': category,
      'tags': tags,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? hostId,
    bool? isLive,
    String? thumbnailUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<String>? stageUserIds,
    List<String>? audienceUserIds,
    int? memberCount,
    String? category,
    List<String>? tags,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      isLive: isLive ?? this.isLive,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stageUserIds: stageUserIds ?? this.stageUserIds,
      audienceUserIds: audienceUserIds ?? this.audienceUserIds,
      memberCount: memberCount ?? this.memberCount,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}





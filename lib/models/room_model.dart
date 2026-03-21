import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String? description;
  final String? rules;
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
  final List<String> coHosts;
  final bool isLocked;
  final int? slowModeSeconds;

  RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.description,
    this.rules,
    this.isLive = false,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
    this.stageUserIds = const [],
    this.audienceUserIds = const [],
    this.memberCount = 0,
    this.category,
    this.tags = const [],
    this.coHosts = const [],
    this.isLocked = false,
    this.slowModeSeconds,
  });

  /// Combined members list (used by UI)
  List<String> get members => [
        ...stageUserIds,
        ...audienceUserIds,
      ];

  factory RoomModel.fromJson(Map<String, dynamic> json, String documentId) {
    return RoomModel(
      id: documentId,
      name: json['name'] ?? 'Untitled Room',
      description: json['description'],
      rules: json['rules'],
      hostId: json['hostId'] ?? '',
      isLive: json['isLive'] ?? false,
      thumbnailUrl: json['thumbnailUrl'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      stageUserIds: List<String>.from(json['stageUserIds'] ?? []),
      audienceUserIds: List<String>.from(json['audienceUserIds'] ?? []),
      memberCount: json['memberCount'] ?? 0,
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      coHosts: List<String>.from(json['coHosts'] ?? []),
      isLocked: json['isLocked'] ?? false,
      slowModeSeconds: json['slowModeSeconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'rules': rules,
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
      'coHosts': coHosts,
      'isLocked': isLocked,
      'slowModeSeconds': slowModeSeconds,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? rules,
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
    List<String>? coHosts,
    bool? isLocked,
    int? slowModeSeconds,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
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
      coHosts: coHosts ?? this.coHosts,
      isLocked: isLocked ?? this.isLocked,
      slowModeSeconds: slowModeSeconds ?? this.slowModeSeconds,
    );
  }
}
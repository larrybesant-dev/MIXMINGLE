class Room {
  final String id;
  final String name;
  final String description;
  final List<String> stageUserIds;
  final List<String> audienceUserIds;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.stageUserIds,
    required this.audienceUserIds,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stageUserIds: (json['stageUserIds'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      audienceUserIds: (json['audienceUserIds'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}

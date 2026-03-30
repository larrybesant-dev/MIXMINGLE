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

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item is String ? item.trim() : item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: _asString(json['id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      stageUserIds: _asStringList(json['stageUserIds']),
      audienceUserIds: _asStringList(json['audienceUserIds']),
    );
  }
}

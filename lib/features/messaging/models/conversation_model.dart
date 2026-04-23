import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return fallback;
}

String? _asNullableString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item is String ? item.trim() : item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

Map<String, String> _asStringMap(dynamic value) {
  if (value is Map) {
    final parsed = <String, String>{};
    value.forEach((key, raw) {
      if (key is String) {
        parsed[key] = _asString(raw);
      }
    });
    return parsed;
  }
  return const <String, String>{};
}

class Conversation {
  final String id;
  final String type; // 'direct' or 'group'
  final List<String> participantIds;
  final Map<String, String> participantNames; // {userId: username}
  final List<String> pinnedBy;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? lastmessageId;
  final String? lastmessagePreview;
  final String? lastmessageenderId;
  final DateTime? lastmessageAt;
  final DateTime createdAt;
  final Map<String, DateTime> lastReadAt; // {userId: lastReadTime}
  final bool isArchived;
  final String status; // 'active' | 'pending'

  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    this.pinnedBy = const [],
    this.groupName,
    this.groupAvatarUrl,
    this.lastmessageId,
    this.lastmessagePreview,
    this.lastmessageenderId,
    this.lastmessageAt,
    required this.createdAt,
    this.lastReadAt = const {},
    this.isArchived = false,
    this.status = 'active',
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String docId) {
    return Conversation(
      id: docId,
      type: _asString(json['type'], fallback: 'direct'),
      participantIds: _asStringList(json['participantIds']),
      participantNames: _asStringMap(json['participantNames']),
      pinnedBy: _asStringList(json['pinnedBy']),
      groupName: _asNullableString(json['groupName']),
      groupAvatarUrl: _asNullableString(json['groupAvatarUrl']),
      lastmessageId: _asNullableString(json['lastmessageId']),
      lastmessagePreview: _asNullableString(json['lastmessagePreview']),
      lastmessageenderId: _asNullableString(json['lastmessageenderId']),
      lastmessageAt: json['lastmessageAt'] == null
          ? null
          : _parseDateTime(json['lastmessageAt']),
      createdAt: _parseDateTime(json['createdAt']),
      lastReadAt: _parseLastReadAt(json['lastReadAt']),
      isArchived: _asBool(json['isArchived']),
      status: _asString(json['status'], fallback: 'active'),
    );
  }

  static Map<String, DateTime> _parseLastReadAt(dynamic value) {
    if (value is! Map) {
      return const <String, DateTime>{};
    }

    final parsed = <String, DateTime>{};
    value.forEach((key, raw) {
      if (key is String) {
        parsed[key] = _parseDateTime(raw);
      }
    });
    return parsed;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'pinnedBy': pinnedBy,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'lastmessageId': lastmessageId,
      'lastmessagePreview': lastmessagePreview,
      'lastmessageenderId': lastmessageenderId,
      'lastmessageAt': lastmessageAt != null ? Timestamp.fromDate(lastmessageAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReadAt': lastReadAt.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'isArchived': isArchived,
      'status': status,
    };
  }

  String getDisplayName(String? currentUserId) {
    if (type == 'group') return groupName ?? 'Group Chat';
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherUserId] ?? 'Unknown User';
  }

  bool hasUnreadmessage(String userId) {
    return lastmessageAt != null &&
        (lastReadAt[userId] == null || lastReadAt[userId]!.isBefore(lastmessageAt!));
  }

  bool isPinnedFor(String userId) => pinnedBy.contains(userId);
}

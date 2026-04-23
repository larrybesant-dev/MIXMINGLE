import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
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
  if (value is bool) return value;
  if (value is num) return value != 0;

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .where((e) => e != null)
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

class MessageModel {
  final String id;
  final String? clientMessageModelId;

  final String conversationId;

  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;

  final String content;

  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? editedAt;

  final bool isDeleted;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    this.clientMessageModelId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    this.expiresAt,
    this.editedAt,
    this.isDeleted = false,
    this.readBy = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String docId) {
    return MessageModel(
      id: docId,
      clientMessageModelId: _asNullableString(json['clientMessageModelId']),
      conversationId: _asString(json['conversationId']),
      senderId: _asString(json['senderId']),
      senderName: _asString(json['senderName'], fallback: 'Unknown'),
      senderAvatarUrl: _asNullableString(json['senderAvatarUrl']),
      content: _asString(json['content']),
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: json['expiresAt'] == null
          ? null
          : _parseDateTime(json['expiresAt']),
      editedAt: json['editedAt'] == null
          ? null
          : _parseDateTime(json['editedAt']),
      isDeleted: _asBool(json['isDeleted']),
      readBy: _asStringList(json['readBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'clientMessageModelId': clientMessageModelId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'readBy': readBy,
    };
  }

  bool isRead(String userId) => readBy.contains(userId);

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

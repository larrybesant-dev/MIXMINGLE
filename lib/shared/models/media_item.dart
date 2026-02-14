import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType {
  image,
  video,
  audio,
  file,
}

class MediaItem {
  final String id;
  final String userId;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime uploadedAt;

  MediaItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.metadata,
    required this.uploadedAt,
  });

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: MediaType.values[map['type'] ?? 0],
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      title: map['title'],
      description: map['description'],
      metadata: map['metadata'],
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'metadata': metadata,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  MediaItem copyWith({
    String? id,
    String? userId,
    MediaType? type,
    String? url,
    String? thumbnailUrl,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? uploadedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.url == url &&
        other.thumbnailUrl == thumbnailUrl &&
        other.title == title &&
        other.description == description &&
        other.metadata == metadata &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        url.hashCode ^
        (thumbnailUrl?.hashCode ?? 0) ^
        (title?.hashCode ?? 0) ^
        (description?.hashCode ?? 0) ^
        (metadata?.hashCode ?? 0) ^
        uploadedAt.hashCode;
  }

  @override
  String toString() {
    return 'MediaItem(id: $id, userId: $userId, type: $type, url: $url, uploadedAt: $uploadedAt)';
  }
}

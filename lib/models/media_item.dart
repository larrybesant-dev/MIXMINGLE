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
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a generated match for a user
class MatchModel {
  final String id; // matchUserId
  final String matchUserId;
  final double score;
  final DateTime createdAt;
  final String status; // 'new', 'viewed', 'liked', 'passed'
  final String displayName;
  final String? photoUrl;
  final int? age;
  final String? bio;

  MatchModel({
    required this.id,
    required this.matchUserId,
    required this.score,
    required this.createdAt,
    required this.status,
    required this.displayName,
    this.photoUrl,
    this.age,
    this.bio,
  });

  /// Create from Firestore document
  factory MatchModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      matchUserId: data['matchUserId'] as String,
      score: (data['score'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'new',
      displayName: data['displayName'] as String? ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      age: data['age'] as int?,
      bio: data['bio'] as String?,
    );
  }

  /// Create from map
  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      matchUserId: map['matchUserId'] as String,
      score: (map['score'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'new',
      displayName: map['displayName'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      age: map['age'] as int?,
      bio: map['bio'] as String?,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'matchUserId': matchUserId,
      'score': score,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'age': age,
      'bio': bio,
    };
  }

  /// Copy with method
  MatchModel copyWith({
    String? id,
    String? matchUserId,
    double? score,
    DateTime? createdAt,
    String? status,
    String? displayName,
    String? photoUrl,
    int? age,
    String? bio,
  }) {
    return MatchModel(
      id: id ?? this.id,
      matchUserId: matchUserId ?? this.matchUserId,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      bio: bio ?? this.bio,
    );
  }
}

/// Model for match history (liked/passed/mutual)
class MatchHistoryModel {
  final String id;
  final String matchUserId;
  final DateTime createdAt;
  final String outcome; // 'liked', 'passed', 'mutual_like'
  final String displayName;
  final String? photoUrl;
  final double? score;

  MatchHistoryModel({
    required this.id,
    required this.matchUserId,
    required this.createdAt,
    required this.outcome,
    required this.displayName,
    this.photoUrl,
    this.score,
  });

  factory MatchHistoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchHistoryModel(
      id: doc.id,
      matchUserId: data['matchUserId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      outcome: data['outcome'] as String,
      displayName: data['displayName'] as String? ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      score: (data['score'] as num?)?.toDouble(),
    );
  }
}



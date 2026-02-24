// lib/models/relationship_model.dart

class RelationshipModel {
  final String userId;
  final String targetUserId;
  final String type; // 'follow', 'friend'

  RelationshipModel({
    required this.userId,
    required this.targetUserId,
    required this.type,
  });
}

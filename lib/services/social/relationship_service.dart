// lib/services/relationship_service.dart

import '../../shared/models/relationship_model.dart';

class RelationshipService {
  final List<RelationshipModel> _relationships = [];

  List<RelationshipModel> getRelationships(String userId) =>
      _relationships.where((r) => r.userId == userId).toList();

  void addRelationship(RelationshipModel relationship) {
    _relationships.add(relationship);
  }
}

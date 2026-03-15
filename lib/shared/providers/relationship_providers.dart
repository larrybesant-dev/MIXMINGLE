// lib/providers/relationship_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/relationship_service.dart';
import '../models/relationship_model.dart';

final relationshipServiceProvider =
    Provider<RelationshipService>((ref) => RelationshipService());
final relationshipListProvider =
    Provider.family<List<RelationshipModel>, String>((ref, userId) =>
        ref.read(relationshipServiceProvider).getRelationships(userId));

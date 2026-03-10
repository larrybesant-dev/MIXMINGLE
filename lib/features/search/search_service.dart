import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String username;
  final String displayName;
  final List<String> interests;
  UserProfile({required this.userId, required this.username, required this.displayName, required this.interests});
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserProfile>> searchUsers(String query) async {
    // Prefix search for username, displayName, interests
    final usersRef = _firestore.collection('users');
    final usernameQuery = await usersRef
      .where('username', isGreaterThanOrEqualTo: query)
      .where('username', isLessThanOrEqualTo: '$query\uf8ff')
      .get();
    final displayNameQuery = await usersRef
      .where('displayName', isGreaterThanOrEqualTo: query)
      .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
      .get();
    final interestsQuery = await usersRef
      .where('interests', arrayContains: query)
      .get();
    final results = <UserProfile>{};
    for (final doc in usernameQuery.docs) {
      results.add(UserProfile(
        userId: doc.id,
        username: doc['username'],
        displayName: doc['displayName'],
        interests: List<String>.from(doc['interests'] ?? []),
      ));
    }
    for (final doc in displayNameQuery.docs) {
      results.add(UserProfile(
        userId: doc.id,
        username: doc['username'],
        displayName: doc['displayName'],
        interests: List<String>.from(doc['interests'] ?? []),
      ));
    }
    for (final doc in interestsQuery.docs) {
      results.add(UserProfile(
        userId: doc.id,
        username: doc['username'],
        displayName: doc['displayName'],
        interests: List<String>.from(doc['interests'] ?? []),
      ));
    }
    return results.toList();
  }
}

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

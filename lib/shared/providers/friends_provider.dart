// Friends List Provider - Manages friends with online/offline status, favorites, search
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_models.dart';

/// Internal Firestore stream of people the current user follows, mapped to Friend objects.
/// Uses users/{uid}/following subcollection.
final _followingFriendsStreamProvider = StreamProvider<List<Friend>>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('users')
      .doc(currentUser.uid)
      .collection('following')
      .snapshots()
      .asyncMap((snapshot) async {
    final followingIds = snapshot.docs.map((d) => d.id).where((id) => id.isNotEmpty).toList();

    if (followingIds.isEmpty) return <Friend>[];

    // Firestore whereIn is limited to 30; chunk if needed
    final List<DocumentSnapshot<Map<String, dynamic>>> userDocs = [];
    for (var i = 0; i < followingIds.length; i += 30) {
      final chunk = followingIds.sublist(i, i + 30 > followingIds.length ? followingIds.length : i + 30);
      final snap = await firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
      userDocs.addAll(snap.docs);
    }

    return userDocs.map((doc) {
      final data = doc.data()!;
      final lastSeenTs = data['lastSeen'] as Timestamp?;
      return Friend(
        id: doc.id,
        name: (data['displayName'] as String?)?.isNotEmpty == true
            ? data['displayName'] as String
            : (data['username'] as String?) ?? 'User',
        avatarUrl: (data['avatarUrl'] as String?) ?? (data['photoUrl'] as String?) ?? '',
        isOnline: (data['isOnline'] as bool?) ?? false,
        lastSeen: lastSeenTs?.toDate() ?? DateTime.now(),
        isFavorite: false,
        unreadMessages: 0,
      );
    }).toList();
  });
});

/// Friends list notifier
class FriendsNotifier extends Notifier<List<Friend>> {
  @override
  List<Friend> build() {
    // Watch the real Firestore stream; update state whenever it emits
    ref.listen<AsyncValue<List<Friend>>>(
      _followingFriendsStreamProvider,
      (_, next) {
        next.whenData((friends) => state = friends);
      },
      fireImmediately: true,
    );
    // Initial state is empty; the listener above will populate it once Firestore responds
    return [];
  }

  /// Toggle favorite status
  void toggleFavorite(String friendId) {
    state = state.map((friend) {
      if (friend.id == friendId) {
        return friend.copyWith(isFavorite: !friend.isFavorite);
      }
      return friend;
    }).toList();
  }

  /// Mark messages as read
  void markMessagesAsRead(String friendId) {
    state = state.map((friend) {
      if (friend.id == friendId) {
        return friend.copyWith(unreadMessages: 0);
      }
      return friend;
    }).toList();
  }

  /// Update online status
  void updateOnlineStatus(String friendId, bool isOnline) {
    state = state.map((friend) {
      if (friend.id == friendId) {
        return friend.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
      }
      return friend;
    }).toList();
  }

  /// Add new message to friend
  void addUnreadMessage(String friendId) {
    state = state.map((friend) {
      if (friend.id == friendId) {
        return friend.copyWith(
          unreadMessages: friend.unreadMessages + 1,
        );
      }
      return friend;
    }).toList();
  }
}

/// Friends provider
final friendsProvider = NotifierProvider<FriendsNotifier, List<Friend>>(
  () => FriendsNotifier(),
);

/// Friend search query notifier
class FriendSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final friendSearchQueryProvider =
    NotifierProvider<FriendSearchQueryNotifier, String>(
  () => FriendSearchQueryNotifier(),
);

/// Filtered friends based on search
final filteredFriendsProvider = FutureProvider<List<Friend>>((ref) {
  final friends = ref.watch(friendsProvider);
  final query = ref.watch(friendSearchQueryProvider);

  return Future.value(
    friends
        .where((friend) =>
            friend.name.toLowerCase().contains(query.toLowerCase()) ||
            friend.id.toLowerCase().contains(query.toLowerCase()))
        .toList(),
  );
});

/// Online friends only
final onlineFriendsProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.where((friend) => friend.isOnline).toList();
});

/// Favorite friends
final favoriteFriendsProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.where((friend) => friend.isFavorite).toList();
});

/// Friends with unread messages
final friendsWithUnreadProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.where((friend) => friend.unreadMessages > 0).toList();
});

/// Total unread messages count
final totalUnreadMessagesProvider = Provider<int>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.fold<int>(0, (acc, friend) => acc + friend.unreadMessages);
});

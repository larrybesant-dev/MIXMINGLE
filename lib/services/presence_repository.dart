import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firestore/firestore_debug_tracing.dart';
import '../core/providers/firebase_providers.dart';
import '../models/presence_model.dart';

abstract class PresenceRepository {
  Stream<PresenceModel> watchUserPresence(String userId);
  Stream<bool> userPresenceStream(String userId);
  Stream<Map<String, PresenceModel>> watchUsersPresence(List<String> userIds);
  Future<Map<String, PresenceModel>> getUsersPresence(List<String> userIds);
  Future<int> countOnlineUsers({int limit = 500});
}

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return FirestorePresenceRepository(ref.watch(firestoreProvider));
});

class FirestorePresenceRepository implements PresenceRepository {
  FirestorePresenceRepository(this._firestore);

  static const int _firestoreWhereInLimit = 30;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('presence').doc(userId);

  List<List<String>> _chunksOf(List<String> values, int size) {
    if (values.isEmpty) {
      return const <List<String>>[];
    }

    final chunks = <List<String>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size) > values.length ? values.length : index + size;
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }

  PresenceModel _parsePresence(String userId, Map<String, dynamic>? data) {
    if (data == null) {
      return PresenceModel(
        userId: userId,
        isOnline: false,
        online: false,
        status: UserStatus.offline,
      );
    }
    return PresenceModel.fromJson({'userId': userId, ...data});
  }

  @override
  Stream<PresenceModel> watchUserPresence(String userId) {
    return traceFirestoreStream<PresenceModel>(
      key: 'presence/$userId',
      query: 'presence/$userId',
      userId: userId,
      itemCount: (_) => 1,
      stream: _ref(userId).snapshots().map((doc) => _parsePresence(userId, doc.data())),
    );
  }

  @override
  Stream<bool> userPresenceStream(String userId) =>
      watchUserPresence(userId).map((presence) => presence.isOnline == true);

  @override
  Stream<Map<String, PresenceModel>> watchUsersPresence(List<String> userIds) {
    final normalizedIds = userIds.toSet().toList(growable: false);
    if (normalizedIds.isEmpty) {
      return Stream.value(const <String, PresenceModel>{});
    }

    return Stream.multi((controller) {
      final chunks = _chunksOf(normalizedIds, _firestoreWhereInLimit);
      final chunkMaps = List<Map<String, PresenceModel>>.generate(
        chunks.length,
        (_) => <String, PresenceModel>{},
      );
      final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

      void emit() {
        final merged = <String, PresenceModel>{};
        for (final chunkMap in chunkMaps) {
          merged.addAll(chunkMap);
        }
        controller.add({
          for (final userId in normalizedIds)
            userId: merged[userId] ?? _parsePresence(userId, null),
        });
      }

      for (var index = 0; index < chunks.length; index += 1) {
        final chunk = chunks[index];
        final sub = _firestore
            .collection('presence')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .listen((snapshot) {
          chunkMaps[index] = {
            for (final doc in snapshot.docs) doc.id: _parsePresence(doc.id, doc.data()),
          };
          emit();
        }, onError: controller.addError);
        subscriptions.add(sub);
      }

      controller.onCancel = () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      };
    });
  }

  @override
  Future<Map<String, PresenceModel>> getUsersPresence(List<String> userIds) async {
    final normalizedIds = userIds.toSet().toList(growable: false);
    if (normalizedIds.isEmpty) {
      return const <String, PresenceModel>{};
    }

    final result = <String, PresenceModel>{};
    final chunks = _chunksOf(normalizedIds, _firestoreWhereInLimit);

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('presence')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = _parsePresence(doc.id, doc.data());
      }
    }

    return {
      for (final userId in normalizedIds)
        userId: result[userId] ?? _parsePresence(userId, null),
    };
  }

  @override
  Future<int> countOnlineUsers({int limit = 500}) async {
    final snapshot = await _firestore
        .collection('presence')
        .where('isOnline', isEqualTo: true)
        .limit(limit + 1)
        .get();

    return snapshot.docs.where((doc) => _parsePresence(doc.id, doc.data()).isOnline == true).length;
  }
}
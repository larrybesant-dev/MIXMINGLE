import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/mic_access_request_model.dart';
import '../../../services/notification_service.dart';
import 'room_firestore_provider.dart';

class MicAccessController {
  MicAccessController(this._db);

  final FirebaseFirestore _db;

  int _asInt(dynamic value, {int fallback = 100}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
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

  CollectionReference<Map<String, dynamic>> _requestCollection(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('mic_access_requests');
  }

  Future<int> _nextPriority(String roomId) async {
    final snapshot = await _requestCollection(roomId)
        .where('status', isEqualTo: 'pending')
        .orderBy('priority', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return 100;
    }
    final value = _asInt(snapshot.docs.first.data()['priority']);
    return value + 10;
  }

  Future<void> _expireStalePendingRequests(String roomId) async {
    final now = Timestamp.fromDate(DateTime.now());
    final staleSnapshot = await _requestCollection(roomId)
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isLessThanOrEqualTo: now)
        .get();
    if (staleSnapshot.docs.isEmpty) {
      return;
    }
    final batch = _db.batch();
    for (final staleDoc in staleSnapshot.docs) {
      batch.update(staleDoc.reference, {
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> requestAccess({
    required String roomId,
    required String requesterId,
    required String hostId,
    int? priority,
  }) async {
    await _expireStalePendingRequests(roomId);

    final existing = await _requestCollection(roomId)
        .where('requesterId', isEqualTo: requesterId)
        .where('hostId', isEqualTo: hostId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final resolvedPriority = priority ?? await _nextPriority(roomId);
    final requestRef = _requestCollection(roomId).doc();
    await requestRef.set({
      'id': requestRef.id,
      'roomId': roomId,
      'requesterId': requesterId,
      'hostId': hostId,
      'status': 'pending',
      'priority': resolvedPriority,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService(firestore: _db).inAppNotification(
      hostId,
      'New mic request from $requesterId in room $roomId.',
    );
  }

  Future<void> bumpPriority(String roomId, String requestId) async {
    final requestRef = _requestCollection(roomId).doc(requestId);
    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      return;
    }
    final current = _asInt(snapshot.data()?['priority']);
    final next = current <= 0 ? 0 : current - 10;
    await requestRef.update({
      'priority': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> lowerPriority(String roomId, String requestId) async {
    final requestRef = _requestCollection(roomId).doc(requestId);
    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      return;
    }
    final current = _asInt(snapshot.data()?['priority']);
    await requestRef.update({
      'priority': current + 10,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> expireNow(String roomId, String requestId) async {
    final requestRef = _requestCollection(roomId).doc(requestId);
    final snapshot = await requestRef.get();
    if (!snapshot.exists) {
      return;
    }
    final requesterId = _asNullableString(snapshot.data()?['requesterId']);
    await requestRef.update({
      'status': 'expired',
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now()),
    });
    if (requesterId != null && requesterId.isNotEmpty) {
      await NotificationService(firestore: _db).inAppNotification(
        requesterId,
        'Your mic access request expired in room $roomId.',
      );
    }
  }

  Future<void> approveRequest(String roomId, MicAccessRequestModel request) async {
    final batch = _db.batch();
    batch.update(_requestCollection(roomId).doc(request.id), {
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.collection('rooms').doc(roomId).collection('participants').doc(request.requesterId),
      {
        'userId': request.requesterId,
        'role': 'stage',
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    await NotificationService(firestore: _db).inAppNotification(
      request.requesterId,
      'Your mic access request was approved in room $roomId.',
    );
  }

  Future<void> denyRequest(String roomId, String requestId) async {
    final requestSnapshot = await _requestCollection(roomId).doc(requestId).get();
    final requesterId = _asNullableString(requestSnapshot.data()?['requesterId']);
    await _requestCollection(roomId).doc(requestId).update({
      'status': 'denied',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (requesterId != null && requesterId.isNotEmpty) {
      await NotificationService(firestore: _db).inAppNotification(
        requesterId,
        'Your mic access request was denied in room $roomId.',
      );
    }
  }
}

final micAccessControllerProvider = Provider<MicAccessController>((ref) {
  return MicAccessController(ref.watch(roomFirestoreProvider));
});

final roomMicAccessRequestsProvider = StreamProvider.autoDispose
    .family<List<MicAccessRequestModel>, String>((ref, roomId) {
  final firestore = ref.watch(roomFirestoreProvider);
  return firestore
      .collection('rooms')
      .doc(roomId)
      .collection('mic_access_requests')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) {
          final requests = snapshot.docs
              .map((doc) => MicAccessRequestModel.fromJson({'id': doc.id, ...doc.data()}))
              .where((request) => !(request.status == 'pending' && request.isExpired))
              .toList(growable: false);
          requests.sort((left, right) {
            if (left.status == 'pending' && right.status != 'pending') {
              return -1;
            }
            if (left.status != 'pending' && right.status == 'pending') {
              return 1;
            }
            final priorityCompare = left.priority.compareTo(right.priority);
            if (priorityCompare != 0) {
              return priorityCompare;
            }
            return left.createdAt.compareTo(right.createdAt);
          });
          return requests;
        },
      );
});

final myMicAccessRequestProvider = StreamProvider.autoDispose.family<MicAccessRequestModel?, ({String roomId, String requesterId})>((ref, params) {
  final firestore = ref.watch(roomFirestoreProvider);
  return firestore
      .collection('rooms')
      .doc(params.roomId)
      .collection('mic_access_requests')
      .where('requesterId', isEqualTo: params.requesterId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }
        final doc = snapshot.docs.first;
        final request = MicAccessRequestModel.fromJson({'id': doc.id, ...doc.data()});
        if (request.status == 'pending' && request.isExpired) {
          return null;
        }
        return request;
      });
});

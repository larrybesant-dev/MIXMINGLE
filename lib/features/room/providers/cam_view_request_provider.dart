import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'room_firestore_provider.dart';

class CamViewRequest {
  const CamViewRequest({
    required this.id,
    required this.requesterId,
    required this.targetId,
    required this.roomId,
    required this.status,
  });

  final String id;
  final String requesterId;
  final String targetId;
  final String roomId;
  final String status;

  factory CamViewRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return CamViewRequest(
      id: doc.id,
      requesterId: (data['requesterId'] as String?) ?? '',
      targetId: (data['targetId'] as String?) ?? '',
      roomId: (data['roomId'] as String?) ?? '',
      status: (data['status'] as String?) ?? '',
    );
  }
}

class CamViewRequestController {
  CamViewRequestController(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String roomId) =>
      _db.collection('rooms').doc(roomId).collection('cam_view_requests');

  String _docId(String requesterId, String targetId) =>
      '${requesterId}_$targetId';

  /// Sends a cam-view request from [requesterId] to [targetId] in [roomId].
  /// Idempotent: does nothing if a pending request already exists.
  Future<void> sendRequest({
    required String roomId,
    required String requesterId,
    required String targetId,
  }) async {
    if (roomId.trim().isEmpty ||
        requesterId.trim().isEmpty ||
        targetId.trim().isEmpty) {
      return;
    }
    final docId = _docId(requesterId, targetId);
    final ref = _col(roomId).doc(docId);
    final snap = await ref.get();
    if (snap.exists && (snap.data()?['status'] as String?) == 'pending') return;

    await ref.set({
      'id': docId,
      'roomId': roomId,
      'requesterId': requesterId,
      'targetId': targetId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks a cam-view request as approved or denied.
  Future<void> respondToRequest({
    required String roomId,
    required String requestId,
    required bool approved,
  }) async {
    await _col(roomId).doc(requestId).update({
      'status': approved ? 'approved' : 'denied',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final camViewRequestControllerProvider =
    Provider<CamViewRequestController>((ref) {
  return CamViewRequestController(ref.watch(roomFirestoreProvider));
});

/// Streams pending cam-view requests directed at [targetId] in [roomId].
/// Only queries by targetId (no composite index needed); status is filtered
/// client-side.
final pendingCamViewRequestsProvider = StreamProvider.autoDispose
    .family<List<CamViewRequest>, ({String roomId, String targetId})>(
        (ref, params) {
      final firestore = ref.watch(roomFirestoreProvider);
      return firestore
          .collection('rooms')
          .doc(params.roomId)
          .collection('cam_view_requests')
          .where('targetId', isEqualTo: params.targetId)
          .snapshots()
          .map((qs) => qs.docs
              .map(CamViewRequest.fromDoc)
              .where((r) => r.status == 'pending')
              .toList(growable: false));
    });

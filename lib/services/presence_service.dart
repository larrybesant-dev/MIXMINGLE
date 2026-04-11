import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore/firestore_debug_tracing.dart';
import '../core/telemetry/app_telemetry.dart';
import '../models/presence_model.dart';

class PresenceService {
  PresenceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('presence').doc(userId);

  Stream<PresenceModel> watchUserPresence(String userId) {
    return traceFirestoreStream<PresenceModel>(
      key: 'presence/$userId',
      query: 'presence/$userId',
      userId: userId,
      itemCount: (_) => 1,
      stream: _ref(userId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) {
          return PresenceModel(
            userId: userId,
            isOnline: false,
            online: false,
            status: UserStatus.offline,
          );
        }
        return PresenceModel.fromJson({'userId': userId, ...data});
      }),
    );
  }

  Stream<bool> userPresenceStream(String userId) =>
      watchUserPresence(userId).map((presence) => presence.isOnline == true);

  Future<void> setStatus(String userId, UserStatus status) async {
    final isOnline = status != UserStatus.offline;
    await traceFirestoreWrite<void>(
      path: 'presence/$userId',
      operation: 'set_presence_status',
      userId: userId,
      metadata: <String, Object?>{'status': status.name},
      action: () => _ref(userId).set({
        'isOnline': isOnline,
        'online': isOnline,
        'status': status.name,
        'userStatus': status.name,
        'lastSeen': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    AppTelemetry.updateRoomState(
      joinedUserId: userId,
      presenceStatus: status.name,
      globalPresenceOnline: isOnline,
    );
  }

  Future<void> setUserOnline(String userId, bool isOnline) =>
      setStatus(userId, isOnline ? UserStatus.online : UserStatus.offline);

  Future<void> setInRoom(String userId, String roomId) async {
    await traceFirestoreWrite<void>(
      path: 'presence/$userId',
      operation: 'set_presence_room',
      roomId: roomId,
      userId: userId,
      metadata: <String, Object?>{'inRoom': roomId},
      action: () => _ref(userId).set({
        'inRoom': roomId,
        'roomId': roomId,
        'lastSeen': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    AppTelemetry.updateRoomState(
      roomId: roomId,
      joinedUserId: userId,
      inRoom: roomId,
    );
  }

  Future<void> clearRoom(String userId) async {
    await traceFirestoreWrite<void>(
      path: 'presence/$userId',
      operation: 'clear_presence_room',
      userId: userId,
      action: () => _ref(userId).set({
        'inRoom': null,
        'roomId': null,
        'lastSeen': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    AppTelemetry.updateRoomState(joinedUserId: userId, inRoom: null);
  }
}

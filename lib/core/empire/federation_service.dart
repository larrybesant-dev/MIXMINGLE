/// Federation Service
///
/// Manages cross-app federation of identity, rooms, creators, and moderation signals.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Federation partner status
enum FederationStatus {
  pending,
  active,
  suspended,
  terminated,
}

/// Federated entity type
enum FederatedEntityType {
  identity,
  room,
  creator,
  moderationSignal,
}

/// Sync direction
enum SyncDirection {
  inbound,
  outbound,
  bidirectional,
}

/// Federation partner
class FederationPartner {
  final String partnerId;
  final String name;
  final String domain;
  final FederationStatus status;
  final String apiEndpoint;
  final String publicKey;
  final List<FederatedEntityType> enabledTypes;
  final SyncDirection syncDirection;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final Map<String, dynamic> metadata;

  const FederationPartner({
    required this.partnerId,
    required this.name,
    required this.domain,
    required this.status,
    required this.apiEndpoint,
    required this.publicKey,
    this.enabledTypes = const [],
    this.syncDirection = SyncDirection.bidirectional,
    required this.createdAt,
    this.lastSyncAt,
    this.metadata = const {},
  });

  factory FederationPartner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FederationPartner(
      partnerId: doc.id,
      name: data['name'] ?? '',
      domain: data['domain'] ?? '',
      status: FederationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => FederationStatus.pending,
      ),
      apiEndpoint: data['apiEndpoint'] ?? '',
      publicKey: data['publicKey'] ?? '',
      enabledTypes: (data['enabledTypes'] as List<dynamic>? ?? [])
          .map((t) => FederatedEntityType.values.firstWhere(
                (ft) => ft.name == t,
                orElse: () => FederatedEntityType.identity,
              ))
          .toList(),
      syncDirection: SyncDirection.values.firstWhere(
        (d) => d.name == data['syncDirection'],
        orElse: () => SyncDirection.bidirectional,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncAt: (data['lastSyncAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'domain': domain,
        'status': status.name,
        'apiEndpoint': apiEndpoint,
        'publicKey': publicKey,
        'enabledTypes': enabledTypes.map((t) => t.name).toList(),
        'syncDirection': syncDirection.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
        'metadata': metadata,
      };
}

/// Federated identity
class FederatedIdentity {
  final String federatedId;
  final String localUserId;
  final String partnerId;
  final String remoteUserId;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime linkedAt;
  final Map<String, dynamic> claims;

  const FederatedIdentity({
    required this.federatedId,
    required this.localUserId,
    required this.partnerId,
    required this.remoteUserId,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    required this.linkedAt,
    this.claims = const {},
  });

  factory FederatedIdentity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FederatedIdentity(
      federatedId: doc.id,
      localUserId: data['localUserId'] ?? '',
      partnerId: data['partnerId'] ?? '',
      remoteUserId: data['remoteUserId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      isVerified: data['isVerified'] ?? false,
      linkedAt: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claims: Map<String, dynamic>.from(data['claims'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'localUserId': localUserId,
        'partnerId': partnerId,
        'remoteUserId': remoteUserId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'linkedAt': Timestamp.fromDate(linkedAt),
        'claims': claims,
      };
}

/// Federated room
class FederatedRoom {
  final String federatedRoomId;
  final String localRoomId;
  final String partnerId;
  final String remoteRoomId;
  final String name;
  final bool isActive;
  final int localParticipants;
  final int remoteParticipants;
  final DateTime federatedAt;

  const FederatedRoom({
    required this.federatedRoomId,
    required this.localRoomId,
    required this.partnerId,
    required this.remoteRoomId,
    required this.name,
    this.isActive = true,
    this.localParticipants = 0,
    this.remoteParticipants = 0,
    required this.federatedAt,
  });

  factory FederatedRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FederatedRoom(
      federatedRoomId: doc.id,
      localRoomId: data['localRoomId'] ?? '',
      partnerId: data['partnerId'] ?? '',
      remoteRoomId: data['remoteRoomId'] ?? '',
      name: data['name'] ?? '',
      isActive: data['isActive'] ?? true,
      localParticipants: data['localParticipants'] ?? 0,
      remoteParticipants: data['remoteParticipants'] ?? 0,
      federatedAt: (data['federatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'localRoomId': localRoomId,
        'partnerId': partnerId,
        'remoteRoomId': remoteRoomId,
        'name': name,
        'isActive': isActive,
        'localParticipants': localParticipants,
        'remoteParticipants': remoteParticipants,
        'federatedAt': Timestamp.fromDate(federatedAt),
      };

  int get totalParticipants => localParticipants + remoteParticipants;
}

/// Federated creator
class FederatedCreator {
  final String federatedCreatorId;
  final String localCreatorId;
  final String partnerId;
  final String remoteCreatorId;
  final String displayName;
  final String? avatarUrl;
  final int followerCount;
  final bool isVerified;
  final DateTime federatedAt;

  const FederatedCreator({
    required this.federatedCreatorId,
    required this.localCreatorId,
    required this.partnerId,
    required this.remoteCreatorId,
    required this.displayName,
    this.avatarUrl,
    this.followerCount = 0,
    this.isVerified = false,
    required this.federatedAt,
  });

  factory FederatedCreator.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FederatedCreator(
      federatedCreatorId: doc.id,
      localCreatorId: data['localCreatorId'] ?? '',
      partnerId: data['partnerId'] ?? '',
      remoteCreatorId: data['remoteCreatorId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      followerCount: data['followerCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      federatedAt: (data['federatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'localCreatorId': localCreatorId,
        'partnerId': partnerId,
        'remoteCreatorId': remoteCreatorId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'followerCount': followerCount,
        'isVerified': isVerified,
        'federatedAt': Timestamp.fromDate(federatedAt),
      };
}

/// Moderation signal
class ModerationSignal {
  final String signalId;
  final String partnerId;
  final String subjectUserId;
  final String signalType;
  final String severity;
  final String description;
  final bool isActionable;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> evidence;

  const ModerationSignal({
    required this.signalId,
    required this.partnerId,
    required this.subjectUserId,
    required this.signalType,
    required this.severity,
    required this.description,
    this.isActionable = true,
    required this.receivedAt,
    this.expiresAt,
    this.evidence = const {},
  });

  factory ModerationSignal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationSignal(
      signalId: doc.id,
      partnerId: data['partnerId'] ?? '',
      subjectUserId: data['subjectUserId'] ?? '',
      signalType: data['signalType'] ?? '',
      severity: data['severity'] ?? 'low',
      description: data['description'] ?? '',
      isActionable: data['isActionable'] ?? true,
      receivedAt: (data['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      evidence: Map<String, dynamic>.from(data['evidence'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'partnerId': partnerId,
        'subjectUserId': subjectUserId,
        'signalType': signalType,
        'severity': severity,
        'description': description,
        'isActionable': isActionable,
        'receivedAt': Timestamp.fromDate(receivedAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'evidence': evidence,
      };

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Federation service singleton
class FederationService {
  static FederationService? _instance;
  static FederationService get instance => _instance ??= FederationService._();

  FederationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _partnersCollection =>
      _firestore.collection('federation_partners');
  CollectionReference get _identitiesCollection =>
      _firestore.collection('federated_identities');
  CollectionReference get _roomsCollection =>
      _firestore.collection('federated_rooms');
  CollectionReference get _creatorsCollection =>
      _firestore.collection('federated_creators');
  CollectionReference get _signalsCollection =>
      _firestore.collection('moderation_signals');

  final StreamController<ModerationSignal> _signalController =
      StreamController<ModerationSignal>.broadcast();

  Stream<ModerationSignal> get signalStream => _signalController.stream;

  // ============================================================
  // IDENTITY FEDERATION
  // ============================================================

  /// Federate a user identity with a partner
  Future<FederatedIdentity> federateIdentity({
    required String localUserId,
    required String partnerId,
    required String remoteUserId,
    required String displayName,
    String? avatarUrl,
    Map<String, dynamic>? claims,
  }) async {
    debugPrint('ðŸ”— [Federation] Federating identity: $localUserId <-> $remoteUserId');

    // Verify partner exists and is active
    final partner = await getPartner(partnerId);
    if (partner == null || partner.status != FederationStatus.active) {
      throw Exception('Federation partner not found or inactive');
    }

    if (!partner.enabledTypes.contains(FederatedEntityType.identity)) {
      throw Exception('Identity federation not enabled for this partner');
    }

    final identityRef = _identitiesCollection.doc();
    final identity = FederatedIdentity(
      federatedId: identityRef.id,
      localUserId: localUserId,
      partnerId: partnerId,
      remoteUserId: remoteUserId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      linkedAt: DateTime.now(),
      claims: claims ?? {},
    );

    await identityRef.set(identity.toFirestore());

    debugPrint('âœ… [Federation] Identity federated: ${identity.federatedId}');
    return identity;
  }

  /// Get federated identities for a user
  Future<List<FederatedIdentity>> getFederatedIdentities(String localUserId) async {
    final snapshot = await _identitiesCollection
        .where('localUserId', isEqualTo: localUserId)
        .get();

    return snapshot.docs.map((doc) => FederatedIdentity.fromFirestore(doc)).toList();
  }

  /// Unlink federated identity
  Future<void> unlinkIdentity(String federatedId) async {
    await _identitiesCollection.doc(federatedId).delete();
    debugPrint('ðŸ”“ [Federation] Identity unlinked: $federatedId');
  }

  // ============================================================
  // ROOM FEDERATION
  // ============================================================

  /// Federate a room with a partner
  Future<FederatedRoom> federateRooms({
    required String localRoomId,
    required String partnerId,
    required String remoteRoomId,
    required String name,
  }) async {
    debugPrint('ðŸ  [Federation] Federating room: $localRoomId <-> $remoteRoomId');

    final partner = await getPartner(partnerId);
    if (partner == null || partner.status != FederationStatus.active) {
      throw Exception('Federation partner not found or inactive');
    }

    if (!partner.enabledTypes.contains(FederatedEntityType.room)) {
      throw Exception('Room federation not enabled for this partner');
    }

    final roomRef = _roomsCollection.doc();
    final room = FederatedRoom(
      federatedRoomId: roomRef.id,
      localRoomId: localRoomId,
      partnerId: partnerId,
      remoteRoomId: remoteRoomId,
      name: name,
      federatedAt: DateTime.now(),
    );

    await roomRef.set(room.toFirestore());

    debugPrint('âœ… [Federation] Room federated: ${room.federatedRoomId}');
    return room;
  }

  /// Get federated rooms
  Future<List<FederatedRoom>> getFederatedRooms({String? partnerId}) async {
    var query = _roomsCollection.where('isActive', isEqualTo: true);

    if (partnerId != null) {
      query = query.where('partnerId', isEqualTo: partnerId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => FederatedRoom.fromFirestore(doc)).toList();
  }

  /// Update room participant counts
  Future<void> updateRoomParticipants(
    String federatedRoomId, {
    int? localParticipants,
    int? remoteParticipants,
  }) async {
    final updates = <String, dynamic>{};
    if (localParticipants != null) {
      updates['localParticipants'] = localParticipants;
    }
    if (remoteParticipants != null) {
      updates['remoteParticipants'] = remoteParticipants;
    }

    if (updates.isNotEmpty) {
      await _roomsCollection.doc(federatedRoomId).update(updates);
    }
  }

  /// Defederate room
  Future<void> defederateRoom(String federatedRoomId) async {
    await _roomsCollection.doc(federatedRoomId).update({
      'isActive': false,
    });
    debugPrint('ðŸ”“ [Federation] Room defederated: $federatedRoomId');
  }

  // ============================================================
  // CREATOR FEDERATION
  // ============================================================

  /// Federate a creator with a partner
  Future<FederatedCreator> federateCreators({
    required String localCreatorId,
    required String partnerId,
    required String remoteCreatorId,
    required String displayName,
    String? avatarUrl,
    bool isVerified = false,
  }) async {
    debugPrint('â­ [Federation] Federating creator: $localCreatorId <-> $remoteCreatorId');

    final partner = await getPartner(partnerId);
    if (partner == null || partner.status != FederationStatus.active) {
      throw Exception('Federation partner not found or inactive');
    }

    if (!partner.enabledTypes.contains(FederatedEntityType.creator)) {
      throw Exception('Creator federation not enabled for this partner');
    }

    final creatorRef = _creatorsCollection.doc();
    final creator = FederatedCreator(
      federatedCreatorId: creatorRef.id,
      localCreatorId: localCreatorId,
      partnerId: partnerId,
      remoteCreatorId: remoteCreatorId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isVerified: isVerified,
      federatedAt: DateTime.now(),
    );

    await creatorRef.set(creator.toFirestore());

    debugPrint('âœ… [Federation] Creator federated: ${creator.federatedCreatorId}');
    return creator;
  }

  /// Get federated creators
  Future<List<FederatedCreator>> getFederatedCreators({String? partnerId}) async {
    var query = _creatorsCollection.orderBy('followerCount', descending: true);

    if (partnerId != null) {
      query = query.where('partnerId', isEqualTo: partnerId);
    }

    final snapshot = await query.limit(100).get();
    return snapshot.docs.map((doc) => FederatedCreator.fromFirestore(doc)).toList();
  }

  // ============================================================
  // MODERATION SIGNALS
  // ============================================================

  /// Send moderation signal to federation partners
  Future<void> federateModerationSignals({
    required String subjectUserId,
    required String signalType,
    required String severity,
    required String description,
    DateTime? expiresAt,
    Map<String, dynamic>? evidence,
  }) async {
    debugPrint('ðŸš¨ [Federation] Broadcasting moderation signal: $signalType');

    // Get all active partners with moderation signal enabled
    final partnersSnapshot = await _partnersCollection
        .where('status', isEqualTo: FederationStatus.active.name)
        .get();

    for (final partnerDoc in partnersSnapshot.docs) {
      final partner = FederationPartner.fromFirestore(partnerDoc);

      if (!partner.enabledTypes.contains(FederatedEntityType.moderationSignal)) {
        continue;
      }

      final signalRef = _signalsCollection.doc();
      final signal = ModerationSignal(
        signalId: signalRef.id,
        partnerId: partner.partnerId,
        subjectUserId: subjectUserId,
        signalType: signalType,
        severity: severity,
        description: description,
        receivedAt: DateTime.now(),
        expiresAt: expiresAt,
        evidence: evidence ?? {},
      );

      await signalRef.set(signal.toFirestore());
      _signalController.add(signal);
    }

    debugPrint('âœ… [Federation] Moderation signal broadcasted');
  }

  /// Receive moderation signal from partner
  Future<void> receiveModerationSignal(ModerationSignal signal) async {
    await _signalsCollection.doc(signal.signalId).set(signal.toFirestore());
    _signalController.add(signal);
    debugPrint('ðŸ“¥ [Federation] Received moderation signal: ${signal.signalId}');
  }

  /// Get moderation signals for a user
  Future<List<ModerationSignal>> getModerationSignals(String subjectUserId) async {
    final snapshot = await _signalsCollection
        .where('subjectUserId', isEqualTo: subjectUserId)
        .where('isActionable', isEqualTo: true)
        .orderBy('receivedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ModerationSignal.fromFirestore(doc))
        .where((s) => !s.isExpired)
        .toList();
  }

  // ============================================================
  // PARTNER MANAGEMENT
  // ============================================================

  /// Register a federation partner
  Future<FederationPartner> registerPartner({
    required String name,
    required String domain,
    required String apiEndpoint,
    required String publicKey,
    List<FederatedEntityType>? enabledTypes,
    SyncDirection syncDirection = SyncDirection.bidirectional,
  }) async {
    debugPrint('ðŸ¤ [Federation] Registering partner: $name');

    final partnerRef = _partnersCollection.doc();
    final partner = FederationPartner(
      partnerId: partnerRef.id,
      name: name,
      domain: domain,
      status: FederationStatus.pending,
      apiEndpoint: apiEndpoint,
      publicKey: publicKey,
      enabledTypes: enabledTypes ?? FederatedEntityType.values,
      syncDirection: syncDirection,
      createdAt: DateTime.now(),
    );

    await partnerRef.set(partner.toFirestore());

    debugPrint('âœ… [Federation] Partner registered: ${partner.partnerId}');
    return partner;
  }

  /// Activate partner
  Future<void> activatePartner(String partnerId) async {
    await _partnersCollection.doc(partnerId).update({
      'status': FederationStatus.active.name,
    });
    debugPrint('âœ… [Federation] Partner activated: $partnerId');
  }

  /// Suspend partner
  Future<void> suspendPartner(String partnerId) async {
    await _partnersCollection.doc(partnerId).update({
      'status': FederationStatus.suspended.name,
    });
    debugPrint('â¸ï¸ [Federation] Partner suspended: $partnerId');
  }

  /// Get partner by ID
  Future<FederationPartner?> getPartner(String partnerId) async {
    final doc = await _partnersCollection.doc(partnerId).get();
    if (!doc.exists) return null;
    return FederationPartner.fromFirestore(doc);
  }

  /// Get all partners
  Future<List<FederationPartner>> getAllPartners({
    FederationStatus? status,
  }) async {
    var query = _partnersCollection.orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => FederationPartner.fromFirestore(doc)).toList();
  }

  /// Get federation statistics
  Future<Map<String, dynamic>> getFederationStatistics() async {
    final partners = await getAllPartners();
    final identities = await _identitiesCollection.get();
    final rooms = await _roomsCollection.where('isActive', isEqualTo: true).get();
    final creators = await _creatorsCollection.get();
    final signals = await _signalsCollection
        .where('isActionable', isEqualTo: true)
        .get();

    return {
      'totalPartners': partners.length,
      'activePartners': partners.where((p) => p.status == FederationStatus.active).length,
      'federatedIdentities': identities.docs.length,
      'federatedRooms': rooms.docs.length,
      'federatedCreators': creators.docs.length,
      'activeSignals': signals.docs.length,
    };
  }

  void dispose() {
    _signalController.close();
  }
}

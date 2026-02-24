/// Enterprise Service
///
/// Manages enterprise/organization accounts including org rooms,
/// moderation, analytics, and billing for business customers.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';

/// Organization account
class Organization {
  final String id;
  final String name;
  final String? domain;
  final OrgPlan plan;
  final OrgStatus status;
  final String primaryContactEmail;
  final String? primaryContactName;
  final int memberCount;
  final int maxMembers;
  final List<String> adminIds;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> branding;
  final DateTime createdAt;
  final DateTime? renewsAt;

  const Organization({
    required this.id,
    required this.name,
    this.domain,
    required this.plan,
    required this.status,
    required this.primaryContactEmail,
    this.primaryContactName,
    this.memberCount = 0,
    required this.maxMembers,
    this.adminIds = const [],
    this.settings = const {},
    this.branding = const {},
    required this.createdAt,
    this.renewsAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'domain': domain,
        'plan': plan.name,
        'status': status.name,
        'primaryContactEmail': primaryContactEmail,
        'primaryContactName': primaryContactName,
        'memberCount': memberCount,
        'maxMembers': maxMembers,
        'adminIds': adminIds,
        'settings': settings,
        'branding': branding,
        'createdAt': createdAt.toIso8601String(),
        'renewsAt': renewsAt?.toIso8601String(),
      };

  factory Organization.fromMap(Map<String, dynamic> map) => Organization(
        id: map['id'] as String,
        name: map['name'] as String,
        domain: map['domain'] as String?,
        plan: OrgPlan.values.firstWhere(
          (p) => p.name == map['plan'],
          orElse: () => OrgPlan.starter,
        ),
        status: OrgStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => OrgStatus.pending,
        ),
        primaryContactEmail: map['primaryContactEmail'] as String,
        primaryContactName: map['primaryContactName'] as String?,
        memberCount: map['memberCount'] as int? ?? 0,
        maxMembers: map['maxMembers'] as int? ?? 10,
        adminIds: List<String>.from(map['adminIds'] ?? []),
        settings: (map['settings'] as Map<String, dynamic>?) ?? {},
        branding: (map['branding'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(map['createdAt'] as String),
        renewsAt: map['renewsAt'] != null
            ? DateTime.parse(map['renewsAt'] as String)
            : null,
      );
}

enum OrgPlan {
  starter,
  professional,
  enterprise,
  custom,
}

enum OrgStatus {
  pending,
  active,
  suspended,
  canceled,
}

/// Organization member
class OrgMember {
  final String id;
  final String orgId;
  final String userId;
  final String email;
  final String? name;
  final OrgRole role;
  final List<String> permissions;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;

  const OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.email,
    this.name,
    required this.role,
    this.permissions = const [],
    required this.joinedAt,
    this.lastActiveAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orgId': orgId,
        'userId': userId,
        'email': email,
        'name': name,
        'role': role.name,
        'permissions': permissions,
        'joinedAt': joinedAt.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      };
}

enum OrgRole {
  owner,
  admin,
  moderator,
  member,
  viewer,
}

/// Organization room
class OrgRoom {
  final String id;
  final String orgId;
  final String title;
  final String? description;
  final OrgRoomType type;
  final OrgRoomAccess access;
  final String hostId;
  final int participantCount;
  final int maxParticipants;
  final bool recordingEnabled;
  final bool moderationEnabled;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? endedAt;

  const OrgRoom({
    required this.id,
    required this.orgId,
    required this.title,
    this.description,
    required this.type,
    required this.access,
    required this.hostId,
    this.participantCount = 0,
    required this.maxParticipants,
    this.recordingEnabled = false,
    this.moderationEnabled = true,
    required this.createdAt,
    this.scheduledAt,
    this.endedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orgId': orgId,
        'title': title,
        'description': description,
        'type': type.name,
        'access': access.name,
        'hostId': hostId,
        'participantCount': participantCount,
        'maxParticipants': maxParticipants,
        'recordingEnabled': recordingEnabled,
        'moderationEnabled': moderationEnabled,
        'createdAt': createdAt.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };
}

enum OrgRoomType {
  meeting,
  webinar,
  townHall,
  training,
  interview,
  event,
}

enum OrgRoomAccess {
  public,
  orgOnly,
  inviteOnly,
  password,
}

/// Moderation action
class ModerationAction {
  final String id;
  final String orgId;
  final String roomId;
  final String targetUserId;
  final String moderatorId;
  final ModerationActionType type;
  final String? reason;
  final Duration? duration;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const ModerationAction({
    required this.id,
    required this.orgId,
    required this.roomId,
    required this.targetUserId,
    required this.moderatorId,
    required this.type,
    this.reason,
    this.duration,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orgId': orgId,
        'roomId': roomId,
        'targetUserId': targetUserId,
        'moderatorId': moderatorId,
        'type': type.name,
        'reason': reason,
        'durationMinutes': duration?.inMinutes,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };
}

enum ModerationActionType {
  warn,
  mute,
  kick,
  ban,
  removeMessage,
  reviewContent,
}

/// Organization analytics
class OrgAnalytics {
  final String orgId;
  final int totalRooms;
  final int activeRooms;
  final int totalParticipants;
  final int uniqueParticipants;
  final double averageRoomDuration;
  final double totalHoursStreamed;
  final Map<String, int> roomsByType;
  final Map<String, int> participantsByDay;
  final DateTime periodStart;
  final DateTime periodEnd;

  const OrgAnalytics({
    required this.orgId,
    required this.totalRooms,
    required this.activeRooms,
    required this.totalParticipants,
    required this.uniqueParticipants,
    required this.averageRoomDuration,
    required this.totalHoursStreamed,
    this.roomsByType = const {},
    this.participantsByDay = const {},
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'totalRooms': totalRooms,
        'activeRooms': activeRooms,
        'totalParticipants': totalParticipants,
        'uniqueParticipants': uniqueParticipants,
        'averageRoomDuration': averageRoomDuration,
        'totalHoursStreamed': totalHoursStreamed,
        'roomsByType': roomsByType,
        'participantsByDay': participantsByDay,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };
}

/// Organization billing
class OrgBilling {
  final String orgId;
  final OrgPlan plan;
  final double monthlyAmount;
  final String currency;
  final BillingCycle cycle;
  final String? paymentMethodId;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final List<BillingInvoice> recentInvoices;

  const OrgBilling({
    required this.orgId,
    required this.plan,
    required this.monthlyAmount,
    this.currency = 'USD',
    required this.cycle,
    this.paymentMethodId,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.recentInvoices = const [],
  });

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'plan': plan.name,
        'monthlyAmount': monthlyAmount,
        'currency': currency,
        'cycle': cycle.name,
        'paymentMethodId': paymentMethodId,
        'currentPeriodStart': currentPeriodStart.toIso8601String(),
        'currentPeriodEnd': currentPeriodEnd.toIso8601String(),
        'recentInvoices': recentInvoices.map((i) => i.toMap()).toList(),
      };
}

enum BillingCycle {
  monthly,
  quarterly,
  annual,
}

class BillingInvoice {
  final String id;
  final double amount;
  final String currency;
  final InvoiceStatus status;
  final DateTime issuedAt;
  final DateTime? paidAt;

  const BillingInvoice({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.issuedAt,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'status': status.name,
        'issuedAt': issuedAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
      };
}

enum InvoiceStatus {
  draft,
  pending,
  paid,
  overdue,
  canceled,
}

/// Enterprise Service
class EnterpriseService {
  static EnterpriseService? _instance;
  static EnterpriseService get instance =>
      _instance ??= EnterpriseService._();

  EnterpriseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _orgController = StreamController<Organization>.broadcast();
  final _roomController = StreamController<OrgRoom>.broadcast();

  Stream<Organization> get orgStream => _orgController.stream;
  Stream<OrgRoom> get roomStream => _roomController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _orgsCollection =>
      _firestore.collection('organizations');

  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      _firestore.collection('org_members');

  CollectionReference<Map<String, dynamic>> get _orgRoomsCollection =>
      _firestore.collection('org_rooms');

  CollectionReference<Map<String, dynamic>> get _moderationCollection =>
      _firestore.collection('moderation_actions');

  CollectionReference<Map<String, dynamic>> get _billingCollection =>
      _firestore.collection('org_billing');

  // ============================================================
  // ORGANIZATION ACCOUNTS
  // ============================================================

  /// Create a new organization account
  Future<Organization> orgAccounts({
    required String name,
    required String primaryContactEmail,
    String? primaryContactName,
    String? domain,
    OrgPlan plan = OrgPlan.starter,
    String? adminUserId,
  }) async {
    debugPrint('ðŸ¢ [Enterprise] Creating organization: $name');

    try {
      final id = 'org_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final maxMembers = _getPlanLimits(plan)['maxMembers'] as int;

      final org = Organization(
        id: id,
        name: name,
        domain: domain,
        plan: plan,
        status: OrgStatus.active,
        primaryContactEmail: primaryContactEmail,
        primaryContactName: primaryContactName,
        maxMembers: maxMembers,
        adminIds: adminUserId != null ? [adminUserId] : [],
        createdAt: DateTime.now(),
        renewsAt: DateTime.now().add(const Duration(days: 30)),
      );

      await _orgsCollection.doc(id).set(org.toMap());

      // Add primary admin as member
      if (adminUserId != null) {
        await _addMember(
          orgId: id,
          userId: adminUserId,
          email: primaryContactEmail,
          name: primaryContactName,
          role: OrgRole.owner,
        );
      }

      // Initialize billing
      await _initializeBilling(id, plan);

      _orgController.add(org);

      AnalyticsService.instance.logEvent(
        name: 'org_created',
        parameters: {'plan': plan.name},
      );

      debugPrint('âœ… [Enterprise] Organization created: $id');
      return org;
    } catch (e) {
      debugPrint('âŒ [Enterprise] Failed to create organization: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _getPlanLimits(OrgPlan plan) => switch (plan) {
        OrgPlan.starter => {
            'maxMembers': 10,
            'maxRooms': 5,
            'maxParticipantsPerRoom': 50,
            'recordingEnabled': false,
            'analyticsEnabled': false,
            'ssoEnabled': false,
          },
        OrgPlan.professional => {
            'maxMembers': 50,
            'maxRooms': 20,
            'maxParticipantsPerRoom': 200,
            'recordingEnabled': true,
            'analyticsEnabled': true,
            'ssoEnabled': false,
          },
        OrgPlan.enterprise => {
            'maxMembers': 500,
            'maxRooms': 100,
            'maxParticipantsPerRoom': 1000,
            'recordingEnabled': true,
            'analyticsEnabled': true,
            'ssoEnabled': true,
          },
        OrgPlan.custom => {
            'maxMembers': 10000,
            'maxRooms': 1000,
            'maxParticipantsPerRoom': 10000,
            'recordingEnabled': true,
            'analyticsEnabled': true,
            'ssoEnabled': true,
          },
      };

  Future<void> _addMember({
    required String orgId,
    required String userId,
    required String email,
    String? name,
    required OrgRole role,
  }) async {
    final memberId = 'mem_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

    final member = OrgMember(
      id: memberId,
      orgId: orgId,
      userId: userId,
      email: email,
      name: name,
      role: role,
      permissions: _getRolePermissions(role),
      joinedAt: DateTime.now(),
    );

    await _membersCollection.doc(memberId).set(member.toMap());

    await _orgsCollection.doc(orgId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  List<String> _getRolePermissions(OrgRole role) => switch (role) {
        OrgRole.owner => [
            'manage_org',
            'manage_billing',
            'manage_members',
            'manage_rooms',
            'moderate',
            'view_analytics',
            'create_rooms',
            'join_rooms',
          ],
        OrgRole.admin => [
            'manage_members',
            'manage_rooms',
            'moderate',
            'view_analytics',
            'create_rooms',
            'join_rooms',
          ],
        OrgRole.moderator => [
            'moderate',
            'view_analytics',
            'create_rooms',
            'join_rooms',
          ],
        OrgRole.member => ['create_rooms', 'join_rooms'],
        OrgRole.viewer => ['join_rooms'],
      };

  /// Get organization by ID
  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _orgsCollection.doc(orgId).get();
    if (!doc.exists) return null;
    return Organization.fromMap(doc.data()!);
  }

  /// Get organization members
  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    final snapshot = await _membersCollection
        .where('orgId', isEqualTo: orgId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return OrgMember(
        id: data['id'] as String,
        orgId: data['orgId'] as String,
        userId: data['userId'] as String,
        email: data['email'] as String,
        name: data['name'] as String?,
        role: OrgRole.values.firstWhere(
          (r) => r.name == data['role'],
        ),
        permissions: List<String>.from(data['permissions'] ?? []),
        joinedAt: DateTime.parse(data['joinedAt'] as String),
        lastActiveAt: data['lastActiveAt'] != null
            ? DateTime.parse(data['lastActiveAt'] as String)
            : null,
      );
    }).toList();
  }

  // ============================================================
  // ORGANIZATION ROOMS
  // ============================================================

  /// Create an organization room
  Future<OrgRoom> orgRooms({
    required String orgId,
    required String title,
    String? description,
    required OrgRoomType type,
    OrgRoomAccess access = OrgRoomAccess.orgOnly,
    required String hostId,
    int? maxParticipants,
    bool recordingEnabled = false,
    DateTime? scheduledAt,
  }) async {
    debugPrint('ðŸšª [Enterprise] Creating org room: $title');

    try {
      // Get org and plan limits
      final org = await getOrganization(orgId);
      if (org == null) {
        throw Exception('Organization not found');
      }

      final limits = _getPlanLimits(org.plan);
      final defaultMax = limits['maxParticipantsPerRoom'] as int;

      final id = 'orgroom_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final room = OrgRoom(
        id: id,
        orgId: orgId,
        title: title,
        description: description,
        type: type,
        access: access,
        hostId: hostId,
        maxParticipants: maxParticipants ?? defaultMax,
        recordingEnabled: recordingEnabled && (limits['recordingEnabled'] as bool),
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
      );

      await _orgRoomsCollection.doc(id).set(room.toMap());

      _roomController.add(room);

      AnalyticsService.instance.logEvent(
        name: 'org_room_created',
        parameters: {
          'org_id': orgId,
          'type': type.name,
          'access': access.name,
        },
      );

      debugPrint('âœ… [Enterprise] Org room created: $id');
      return room;
    } catch (e) {
      debugPrint('âŒ [Enterprise] Failed to create org room: $e');
      rethrow;
    }
  }

  /// Get organization rooms
  Future<List<OrgRoom>> getOrgRooms(String orgId, {OrgRoomType? type}) async {
    Query<Map<String, dynamic>> query =
        _orgRoomsCollection.where('orgId', isEqualTo: orgId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return OrgRoom(
        id: data['id'] as String,
        orgId: data['orgId'] as String,
        title: data['title'] as String,
        description: data['description'] as String?,
        type: OrgRoomType.values.firstWhere(
          (t) => t.name == data['type'],
        ),
        access: OrgRoomAccess.values.firstWhere(
          (a) => a.name == data['access'],
        ),
        hostId: data['hostId'] as String,
        participantCount: data['participantCount'] as int? ?? 0,
        maxParticipants: data['maxParticipants'] as int,
        recordingEnabled: data['recordingEnabled'] as bool? ?? false,
        moderationEnabled: data['moderationEnabled'] as bool? ?? true,
        createdAt: DateTime.parse(data['createdAt'] as String),
        scheduledAt: data['scheduledAt'] != null
            ? DateTime.parse(data['scheduledAt'] as String)
            : null,
        endedAt: data['endedAt'] != null
            ? DateTime.parse(data['endedAt'] as String)
            : null,
      );
    }).toList();
  }

  // ============================================================
  // ORGANIZATION MODERATION
  // ============================================================

  /// Take a moderation action
  Future<ModerationAction> orgModeration({
    required String orgId,
    required String roomId,
    required String targetUserId,
    required String moderatorId,
    required ModerationActionType type,
    String? reason,
    Duration? duration,
  }) async {
    debugPrint('âš”ï¸ [Enterprise] Moderation action: ${type.name}');

    try {
      final id = 'mod_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final action = ModerationAction(
        id: id,
        orgId: orgId,
        roomId: roomId,
        targetUserId: targetUserId,
        moderatorId: moderatorId,
        type: type,
        reason: reason,
        duration: duration,
        createdAt: now,
        expiresAt: duration != null ? now.add(duration) : null,
      );

      await _moderationCollection.doc(id).set(action.toMap());

      AnalyticsService.instance.logEvent(
        name: 'moderation_action',
        parameters: {
          'org_id': orgId,
          'type': type.name,
        },
      );

      debugPrint('âœ… [Enterprise] Moderation action recorded: $id');
      return action;
    } catch (e) {
      debugPrint('âŒ [Enterprise] Moderation action failed: $e');
      rethrow;
    }
  }

  /// Get moderation history
  Future<List<ModerationAction>> getModerationHistory(
    String orgId, {
    String? roomId,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query =
        _moderationCollection.where('orgId', isEqualTo: orgId);

    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ModerationAction(
        id: data['id'] as String,
        orgId: data['orgId'] as String,
        roomId: data['roomId'] as String,
        targetUserId: data['targetUserId'] as String,
        moderatorId: data['moderatorId'] as String,
        type: ModerationActionType.values.firstWhere(
          (t) => t.name == data['type'],
        ),
        reason: data['reason'] as String?,
        duration: data['durationMinutes'] != null
            ? Duration(minutes: data['durationMinutes'] as int)
            : null,
        createdAt: DateTime.parse(data['createdAt'] as String),
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'] as String)
            : null,
      );
    }).toList();
  }

  // ============================================================
  // ORGANIZATION ANALYTICS
  // ============================================================

  /// Get organization analytics
  Future<OrgAnalytics> orgAnalytics(
    String orgId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('ðŸ“Š [Enterprise] Fetching org analytics: $orgId');

    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    try {
      // Fetch rooms in period
      final roomsSnapshot = await _orgRoomsCollection
          .where('orgId', isEqualTo: orgId)
          .where('createdAt', isGreaterThanOrEqualTo: periodStart.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: periodEnd.toIso8601String())
          .get();

      // Calculate metrics
      int totalParticipants = 0;
      const double totalDuration = 0;
      final roomsByType = <String, int>{};
      final uniqueParticipantIds = <String>{};

      for (final doc in roomsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final participants = data['participantCount'] as int? ?? 0;

        totalParticipants += participants;
        roomsByType[type] = (roomsByType[type] ?? 0) + 1;

        // Simulate unique participants (in production, track actual IDs)
        uniqueParticipantIds.add('user_${doc.id}');
      }

      final activeRooms = roomsSnapshot.docs
          .where((doc) => doc.data()['endedAt'] == null)
          .length;

      final analytics = OrgAnalytics(
        orgId: orgId,
        totalRooms: roomsSnapshot.docs.length,
        activeRooms: activeRooms,
        totalParticipants: totalParticipants,
        uniqueParticipants: uniqueParticipantIds.length,
        averageRoomDuration: totalDuration / (roomsSnapshot.docs.isNotEmpty ? roomsSnapshot.docs.length : 1),
        totalHoursStreamed: totalDuration / 60,
        roomsByType: roomsByType,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      debugPrint('âœ… [Enterprise] Analytics fetched');
      return analytics;
    } catch (e) {
      debugPrint('âŒ [Enterprise] Failed to fetch analytics: $e');
      rethrow;
    }
  }

  // ============================================================
  // ORGANIZATION BILLING
  // ============================================================

  /// Get organization billing
  Future<OrgBilling> orgBilling(String orgId) async {
    debugPrint('ðŸ’³ [Enterprise] Fetching org billing: $orgId');

    try {
      final doc = await _billingCollection.doc(orgId).get();

      if (!doc.exists) {
        // Initialize billing if not exists
        final org = await getOrganization(orgId);
        if (org == null) throw Exception('Organization not found');

        await _initializeBilling(orgId, org.plan);
        return orgBilling(orgId);
      }

      final data = doc.data()!;
      return OrgBilling(
        orgId: data['orgId'] as String,
        plan: OrgPlan.values.firstWhere(
          (p) => p.name == data['plan'],
        ),
        monthlyAmount: (data['monthlyAmount'] as num).toDouble(),
        currency: data['currency'] as String? ?? 'USD',
        cycle: BillingCycle.values.firstWhere(
          (c) => c.name == data['cycle'],
          orElse: () => BillingCycle.monthly,
        ),
        paymentMethodId: data['paymentMethodId'] as String?,
        currentPeriodStart: DateTime.parse(data['currentPeriodStart'] as String),
        currentPeriodEnd: DateTime.parse(data['currentPeriodEnd'] as String),
        recentInvoices: (data['recentInvoices'] as List?)
                ?.map((i) => BillingInvoice(
                      id: i['id'] as String,
                      amount: (i['amount'] as num).toDouble(),
                      currency: i['currency'] as String? ?? 'USD',
                      status: InvoiceStatus.values.firstWhere(
                        (s) => s.name == i['status'],
                      ),
                      issuedAt: DateTime.parse(i['issuedAt'] as String),
                      paidAt: i['paidAt'] != null
                          ? DateTime.parse(i['paidAt'] as String)
                          : null,
                    ))
                .toList() ??
            [],
      );
    } catch (e) {
      debugPrint('âŒ [Enterprise] Failed to fetch billing: $e');
      rethrow;
    }
  }

  Future<void> _initializeBilling(String orgId, OrgPlan plan) async {
    final pricing = _getPlanPricing(plan);
    final now = DateTime.now();

    await _billingCollection.doc(orgId).set({
      'orgId': orgId,
      'plan': plan.name,
      'monthlyAmount': pricing,
      'currency': 'USD',
      'cycle': BillingCycle.monthly.name,
      'currentPeriodStart': now.toIso8601String(),
      'currentPeriodEnd': now.add(const Duration(days: 30)).toIso8601String(),
      'recentInvoices': [],
    });
  }

  double _getPlanPricing(OrgPlan plan) => switch (plan) {
        OrgPlan.starter => 0,
        OrgPlan.professional => 99,
        OrgPlan.enterprise => 499,
        OrgPlan.custom => 999,
      };

  /// Update organization plan
  Future<bool> upgradePlan(String orgId, OrgPlan newPlan) async {
    try {
      final pricing = _getPlanPricing(newPlan);
      final limits = _getPlanLimits(newPlan);

      await _orgsCollection.doc(orgId).update({
        'plan': newPlan.name,
        'maxMembers': limits['maxMembers'],
      });

      await _billingCollection.doc(orgId).update({
        'plan': newPlan.name,
        'monthlyAmount': pricing,
      });

      return true;
    } catch (e) {
      debugPrint('âŒ [Enterprise] Plan upgrade failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _orgController.close();
    _roomController.close();
  }
}

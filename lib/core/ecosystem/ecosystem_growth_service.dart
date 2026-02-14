/// Ecosystem Growth Service
///
/// Manages platform growth including creator/partner/app recruitment
/// and growth campaigns.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Recruitment campaign
class RecruitmentCampaign {
  final String id;
  final String name;
  final RecruitmentTarget target;
  final CampaignType type;
  final CampaignStatus status;
  final String? description;
  final List<String> channels;
  final double budget;
  final double spent;
  final int targetCount;
  final int recruitedCount;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> incentives;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const RecruitmentCampaign({
    required this.id,
    required this.name,
    required this.target,
    required this.type,
    required this.status,
    this.description,
    this.channels = const [],
    this.budget = 0,
    this.spent = 0,
    this.targetCount = 0,
    this.recruitedCount = 0,
    this.criteria = const {},
    this.incentives = const {},
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target': target.name,
        'type': type.name,
        'status': status.name,
        'description': description,
        'channels': channels,
        'budget': budget,
        'spent': spent,
        'targetCount': targetCount,
        'recruitedCount': recruitedCount,
        'criteria': criteria,
        'incentives': incentives,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecruitmentCampaign.fromMap(Map<String, dynamic> map) =>
      RecruitmentCampaign(
        id: map['id'] as String,
        name: map['name'] as String,
        target: RecruitmentTarget.values.firstWhere(
          (t) => t.name == map['target'],
        ),
        type: CampaignType.values.firstWhere(
          (t) => t.name == map['type'],
        ),
        status: CampaignStatus.values.firstWhere(
          (s) => s.name == map['status'],
        ),
        description: map['description'] as String?,
        channels: List<String>.from(map['channels'] ?? []),
        budget: (map['budget'] as num?)?.toDouble() ?? 0,
        spent: (map['spent'] as num?)?.toDouble() ?? 0,
        targetCount: map['targetCount'] as int? ?? 0,
        recruitedCount: map['recruitedCount'] as int? ?? 0,
        criteria: (map['criteria'] as Map<String, dynamic>?) ?? {},
        incentives: (map['incentives'] as Map<String, dynamic>?) ?? {},
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] != null
            ? DateTime.parse(map['endDate'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

enum RecruitmentTarget {
  creator,
  partner,
  app,
  enterprise,
}

enum CampaignType {
  organic,
  paid,
  referral,
  partnership,
  event,
  outreach,
}

enum CampaignStatus {
  draft,
  scheduled,
  active,
  paused,
  completed,
  canceled,
}

/// Recruitment lead
class RecruitmentLead {
  final String id;
  final String campaignId;
  final RecruitmentTarget type;
  final LeadStatus status;
  final String? name;
  final String? email;
  final String? company;
  final String? source;
  final int followerCount;
  final Map<String, dynamic> profile;
  final List<String> notes;
  final DateTime createdAt;
  final DateTime? convertedAt;

  const RecruitmentLead({
    required this.id,
    required this.campaignId,
    required this.type,
    required this.status,
    this.name,
    this.email,
    this.company,
    this.source,
    this.followerCount = 0,
    this.profile = const {},
    this.notes = const [],
    required this.createdAt,
    this.convertedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'campaignId': campaignId,
        'type': type.name,
        'status': status.name,
        'name': name,
        'email': email,
        'company': company,
        'source': source,
        'followerCount': followerCount,
        'profile': profile,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'convertedAt': convertedAt?.toIso8601String(),
      };
}

enum LeadStatus {
  new_,
  contacted,
  interested,
  negotiating,
  converted,
  rejected,
  inactive,
}

/// Growth campaign (marketing)
class GrowthCampaign {
  final String id;
  final String name;
  final GrowthGoal goal;
  final CampaignStatus status;
  final String? description;
  final List<String> targetAudiences;
  final List<String> channels;
  final double budget;
  final double spent;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> targeting;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const GrowthCampaign({
    required this.id,
    required this.name,
    required this.goal,
    required this.status,
    this.description,
    this.targetAudiences = const [],
    this.channels = const [],
    this.budget = 0,
    this.spent = 0,
    this.metrics = const {},
    this.targeting = const {},
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'goal': goal.name,
        'status': status.name,
        'description': description,
        'targetAudiences': targetAudiences,
        'channels': channels,
        'budget': budget,
        'spent': spent,
        'metrics': metrics,
        'targeting': targeting,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

enum GrowthGoal {
  userAcquisition,
  engagement,
  retention,
  monetization,
  brandAwareness,
  marketExpansion,
}

/// Ecosystem health metrics
class EcosystemHealth {
  final double overallScore;
  final int totalCreators;
  final int activeCreators;
  final int totalPartners;
  final int activePartners;
  final int totalApps;
  final int activeApps;
  final double creatorGrowthRate;
  final double partnerGrowthRate;
  final double appGrowthRate;
  final double userRetention;
  final double revenueGrowth;
  final Map<String, double> healthFactors;
  final DateTime calculatedAt;

  const EcosystemHealth({
    required this.overallScore,
    this.totalCreators = 0,
    this.activeCreators = 0,
    this.totalPartners = 0,
    this.activePartners = 0,
    this.totalApps = 0,
    this.activeApps = 0,
    this.creatorGrowthRate = 0,
    this.partnerGrowthRate = 0,
    this.appGrowthRate = 0,
    this.userRetention = 0,
    this.revenueGrowth = 0,
    this.healthFactors = const {},
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() => {
        'overallScore': overallScore,
        'totalCreators': totalCreators,
        'activeCreators': activeCreators,
        'totalPartners': totalPartners,
        'activePartners': activePartners,
        'totalApps': totalApps,
        'activeApps': activeApps,
        'creatorGrowthRate': creatorGrowthRate,
        'partnerGrowthRate': partnerGrowthRate,
        'appGrowthRate': appGrowthRate,
        'userRetention': userRetention,
        'revenueGrowth': revenueGrowth,
        'healthFactors': healthFactors,
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

/// Expansion opportunity
class ExpansionOpportunity {
  final String id;
  final String name;
  final OpportunityType type;
  final OpportunityPriority priority;
  final String description;
  final String? region;
  final String? vertical;
  final double potentialValue;
  final double confidence;
  final List<String> requirements;
  final List<String> risks;
  final DateTime identifiedAt;

  const ExpansionOpportunity({
    required this.id,
    required this.name,
    required this.type,
    required this.priority,
    required this.description,
    this.region,
    this.vertical,
    this.potentialValue = 0,
    this.confidence = 0,
    this.requirements = const [],
    this.risks = const [],
    required this.identifiedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'priority': priority.name,
        'description': description,
        'region': region,
        'vertical': vertical,
        'potentialValue': potentialValue,
        'confidence': confidence,
        'requirements': requirements,
        'risks': risks,
        'identifiedAt': identifiedAt.toIso8601String(),
      };
}

enum OpportunityType {
  geographic,
  vertical,
  product,
  partnership,
  acquisition,
}

enum OpportunityPriority {
  critical,
  high,
  medium,
  low,
}

/// Ecosystem Growth Service
class EcosystemGrowthService {
  static EcosystemGrowthService? _instance;
  static EcosystemGrowthService get instance =>
      _instance ??= EcosystemGrowthService._();

  EcosystemGrowthService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _campaignController = StreamController<RecruitmentCampaign>.broadcast();
  final _leadController = StreamController<RecruitmentLead>.broadcast();

  Stream<RecruitmentCampaign> get campaignStream => _campaignController.stream;
  Stream<RecruitmentLead> get leadStream => _leadController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _recruitmentCollection =>
      _firestore.collection('recruitment_campaigns');

  CollectionReference<Map<String, dynamic>> get _leadsCollection =>
      _firestore.collection('recruitment_leads');

  CollectionReference<Map<String, dynamic>> get _growthCampaignsCollection =>
      _firestore.collection('growth_campaigns');

  CollectionReference<Map<String, dynamic>> get _opportunitiesCollection =>
      _firestore.collection('expansion_opportunities');

  // ============================================================
  // RECRUIT CREATORS
  // ============================================================

  /// Create a creator recruitment campaign
  Future<RecruitmentCampaign> recruitCreators({
    required String name,
    CampaignType type = CampaignType.organic,
    String? description,
    List<String>? channels,
    double budget = 0,
    int targetCount = 100,
    Map<String, dynamic>? criteria,
    Map<String, dynamic>? incentives,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🎯 [EcosystemGrowth] Creating creator recruitment: $name');

    try {
      final id = 'recruit_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final campaign = RecruitmentCampaign(
        id: id,
        name: name,
        target: RecruitmentTarget.creator,
        type: type,
        status: CampaignStatus.active,
        description: description,
        channels: channels ?? ['social', 'email', 'referral'],
        budget: budget,
        targetCount: targetCount,
        criteria: criteria ??
            {
              'minFollowers': 1000,
              'engagement': 'medium',
              'contentType': 'any',
            },
        incentives: incentives ??
            {
              'signupBonus': 50,
              'firstStreamBonus': 100,
              'referralBonus': 25,
            },
        startDate: startDate ?? now,
        endDate: endDate,
        createdAt: now,
      );

      await _recruitmentCollection.doc(id).set(campaign.toMap());

      _campaignController.add(campaign);

      AnalyticsService.instance.logEvent(
        name: 'recruitment_created',
        parameters: {
          'target': 'creator',
          'type': type.name,
        },
      );

      debugPrint('✅ [EcosystemGrowth] Creator recruitment created: $id');
      return campaign;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to create recruitment: $e');
      rethrow;
    }
  }

  // ============================================================
  // RECRUIT PARTNERS
  // ============================================================

  /// Create a partner recruitment campaign
  Future<RecruitmentCampaign> recruitPartners({
    required String name,
    CampaignType type = CampaignType.outreach,
    String? description,
    List<String>? channels,
    double budget = 0,
    int targetCount = 50,
    Map<String, dynamic>? criteria,
    Map<String, dynamic>? incentives,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🎯 [EcosystemGrowth] Creating partner recruitment: $name');

    try {
      final id = 'recruit_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final campaign = RecruitmentCampaign(
        id: id,
        name: name,
        target: RecruitmentTarget.partner,
        type: type,
        status: CampaignStatus.active,
        description: description,
        channels: channels ?? ['linkedin', 'cold_email', 'conferences'],
        budget: budget,
        targetCount: targetCount,
        criteria: criteria ??
            {
              'industry': 'any',
              'companySize': 'medium+',
              'reach': 10000,
            },
        incentives: incentives ??
            {
              'commissionRate': 20,
              'signupBonus': 500,
              'exclusiveDeals': true,
            },
        startDate: startDate ?? now,
        endDate: endDate,
        createdAt: now,
      );

      await _recruitmentCollection.doc(id).set(campaign.toMap());

      _campaignController.add(campaign);

      debugPrint('✅ [EcosystemGrowth] Partner recruitment created: $id');
      return campaign;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to create recruitment: $e');
      rethrow;
    }
  }

  // ============================================================
  // RECRUIT APPS
  // ============================================================

  /// Create an app/developer recruitment campaign
  Future<RecruitmentCampaign> recruitApps({
    required String name,
    CampaignType type = CampaignType.partnership,
    String? description,
    List<String>? channels,
    double budget = 0,
    int targetCount = 20,
    Map<String, dynamic>? criteria,
    Map<String, dynamic>? incentives,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🎯 [EcosystemGrowth] Creating app recruitment: $name');

    try {
      final id = 'recruit_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final campaign = RecruitmentCampaign(
        id: id,
        name: name,
        target: RecruitmentTarget.app,
        type: type,
        status: CampaignStatus.active,
        description: description,
        channels: channels ?? ['github', 'devrel', 'hackathons'],
        budget: budget,
        targetCount: targetCount,
        criteria: criteria ??
            {
              'platform': 'any',
              'userBase': 5000,
              'category': 'any',
            },
        incentives: incentives ??
            {
              'apiCredits': 10000,
              'prioritySupport': true,
              'coMarketing': true,
            },
        startDate: startDate ?? now,
        endDate: endDate,
        createdAt: now,
      );

      await _recruitmentCollection.doc(id).set(campaign.toMap());

      _campaignController.add(campaign);

      debugPrint('✅ [EcosystemGrowth] App recruitment created: $id');
      return campaign;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to create recruitment: $e');
      rethrow;
    }
  }

  // ============================================================
  // RUN GROWTH CAMPAIGNS
  // ============================================================

  /// Create a growth campaign
  Future<GrowthCampaign> runGrowthCampaigns({
    required String name,
    required GrowthGoal goal,
    String? description,
    List<String>? targetAudiences,
    List<String>? channels,
    double budget = 0,
    Map<String, dynamic>? targeting,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('📈 [EcosystemGrowth] Creating growth campaign: $name');

    try {
      final id = 'growth_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final campaign = GrowthCampaign(
        id: id,
        name: name,
        goal: goal,
        status: CampaignStatus.active,
        description: description,
        targetAudiences:
            targetAudiences ?? ['new_users', 'lapsed_users', 'power_users'],
        channels: channels ?? ['push', 'email', 'in_app', 'social'],
        budget: budget,
        metrics: {
          'impressions': 0,
          'clicks': 0,
          'conversions': 0,
          'ctr': 0,
          'cpa': 0,
        },
        targeting: targeting ??
            {
              'demographics': 'all',
              'interests': 'streaming',
              'behavior': 'active',
            },
        startDate: startDate ?? now,
        endDate: endDate,
        createdAt: now,
      );

      await _growthCampaignsCollection.doc(id).set(campaign.toMap());

      AnalyticsService.instance.logEvent(
        name: 'growth_campaign_created',
        parameters: {
          'goal': goal.name,
        },
      );

      debugPrint('✅ [EcosystemGrowth] Growth campaign created: $id');
      return campaign;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to create growth campaign: $e');
      rethrow;
    }
  }

  // ============================================================
  // LEAD MANAGEMENT
  // ============================================================

  /// Add a recruitment lead
  Future<RecruitmentLead> addLead({
    required String campaignId,
    required RecruitmentTarget type,
    String? name,
    String? email,
    String? company,
    String? source,
    int followerCount = 0,
    Map<String, dynamic>? profile,
  }) async {
    debugPrint('📝 [EcosystemGrowth] Adding lead for campaign: $campaignId');

    try {
      final id = 'lead_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final lead = RecruitmentLead(
        id: id,
        campaignId: campaignId,
        type: type,
        status: LeadStatus.new_,
        name: name,
        email: email,
        company: company,
        source: source,
        followerCount: followerCount,
        profile: profile ?? {},
        createdAt: DateTime.now(),
      );

      await _leadsCollection.doc(id).set(lead.toMap());

      _leadController.add(lead);

      debugPrint('✅ [EcosystemGrowth] Lead added: $id');
      return lead;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to add lead: $e');
      rethrow;
    }
  }

  /// Update lead status
  Future<bool> updateLeadStatus(
    String leadId,
    LeadStatus status, {
    String? note,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      if (status == LeadStatus.converted) {
        updates['convertedAt'] = DateTime.now().toIso8601String();
      }

      if (note != null) {
        updates['notes'] = FieldValue.arrayUnion([note]);
      }

      await _leadsCollection.doc(leadId).update(updates);
      return true;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to update lead: $e');
      return false;
    }
  }

  /// Get leads for a campaign
  Future<List<RecruitmentLead>> getLeads(
    String campaignId, {
    LeadStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query =
        _leadsCollection.where('campaignId', isEqualTo: campaignId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return RecruitmentLead(
        id: data['id'] as String,
        campaignId: data['campaignId'] as String,
        type: RecruitmentTarget.values.firstWhere(
          (t) => t.name == data['type'],
        ),
        status: LeadStatus.values.firstWhere(
          (s) => s.name == data['status'],
        ),
        name: data['name'] as String?,
        email: data['email'] as String?,
        company: data['company'] as String?,
        source: data['source'] as String?,
        followerCount: data['followerCount'] as int? ?? 0,
        profile: (data['profile'] as Map<String, dynamic>?) ?? {},
        notes: List<String>.from(data['notes'] ?? []),
        createdAt: DateTime.parse(data['createdAt'] as String),
        convertedAt: data['convertedAt'] != null
            ? DateTime.parse(data['convertedAt'] as String)
            : null,
      );
    }).toList();
  }

  // ============================================================
  // ECOSYSTEM HEALTH
  // ============================================================

  /// Get ecosystem health metrics
  Future<EcosystemHealth> getEcosystemHealth() async {
    debugPrint('💚 [EcosystemGrowth] Calculating ecosystem health');

    try {
      // In production, these would come from actual data
      // For now, simulate metrics
      final health = EcosystemHealth(
        overallScore: 78.5,
        totalCreators: 5234,
        activeCreators: 3421,
        totalPartners: 156,
        activePartners: 98,
        totalApps: 47,
        activeApps: 32,
        creatorGrowthRate: 12.5,
        partnerGrowthRate: 8.3,
        appGrowthRate: 15.2,
        userRetention: 67.4,
        revenueGrowth: 23.1,
        healthFactors: {
          'creatorSatisfaction': 82.0,
          'partnerEngagement': 75.0,
          'appEcosystem': 70.0,
          'platformStability': 95.0,
          'communityHealth': 78.0,
        },
        calculatedAt: DateTime.now(),
      );

      return health;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to calculate health: $e');
      rethrow;
    }
  }

  // ============================================================
  // EXPANSION OPPORTUNITIES
  // ============================================================

  /// Identify expansion opportunities
  Future<List<ExpansionOpportunity>> getExpansionOpportunities() async {
    debugPrint('🔍 [EcosystemGrowth] Fetching expansion opportunities');

    try {
      final snapshot = await _opportunitiesCollection
          .orderBy('identifiedAt', descending: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        // Return default opportunities if none exist
        return _getDefaultOpportunities();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ExpansionOpportunity(
          id: data['id'] as String,
          name: data['name'] as String,
          type: OpportunityType.values.firstWhere(
            (t) => t.name == data['type'],
          ),
          priority: OpportunityPriority.values.firstWhere(
            (p) => p.name == data['priority'],
          ),
          description: data['description'] as String,
          region: data['region'] as String?,
          vertical: data['vertical'] as String?,
          potentialValue: (data['potentialValue'] as num?)?.toDouble() ?? 0,
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
          requirements: List<String>.from(data['requirements'] ?? []),
          risks: List<String>.from(data['risks'] ?? []),
          identifiedAt: DateTime.parse(data['identifiedAt'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to fetch opportunities: $e');
      return _getDefaultOpportunities();
    }
  }

  List<ExpansionOpportunity> _getDefaultOpportunities() => [
        ExpansionOpportunity(
          id: 'opp_1',
          name: 'LATAM Expansion',
          type: OpportunityType.geographic,
          priority: OpportunityPriority.high,
          description: 'Expand to Latin American markets with localized content',
          region: 'Latin America',
          potentialValue: 500000,
          confidence: 0.75,
          requirements: ['Localization', 'Payment methods', 'Content moderation'],
          risks: ['Regulatory compliance', 'Currency volatility'],
          identifiedAt: DateTime.now(),
        ),
        ExpansionOpportunity(
          id: 'opp_2',
          name: 'Gaming Vertical',
          type: OpportunityType.vertical,
          priority: OpportunityPriority.critical,
          description: 'Target gaming creators and eSports organizations',
          vertical: 'Gaming',
          potentialValue: 1000000,
          confidence: 0.85,
          requirements: ['Gaming features', 'Tournament support', 'Streaming quality'],
          risks: ['Competition', 'High acquisition costs'],
          identifiedAt: DateTime.now(),
        ),
        ExpansionOpportunity(
          id: 'opp_3',
          name: 'Enterprise Education',
          type: OpportunityType.product,
          priority: OpportunityPriority.medium,
          description: 'Develop features for educational institutions',
          vertical: 'Education',
          potentialValue: 300000,
          confidence: 0.65,
          requirements: ['LMS integration', 'Compliance features', 'Bulk pricing'],
          risks: ['Long sales cycles', 'Feature requirements'],
          identifiedAt: DateTime.now(),
        ),
      ];

  // ============================================================
  // CAMPAIGN MANAGEMENT
  // ============================================================

  /// Get recruitment campaigns
  Future<List<RecruitmentCampaign>> getRecruitmentCampaigns({
    RecruitmentTarget? target,
    CampaignStatus? status,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _recruitmentCollection;

    if (target != null) {
      query = query.where('target', isEqualTo: target.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs
        .map((doc) => RecruitmentCampaign.fromMap(doc.data()))
        .toList();
  }

  /// Pause a campaign
  Future<bool> pauseCampaign(String campaignId, {bool isGrowth = false}) async {
    try {
      final collection = isGrowth ? _growthCampaignsCollection : _recruitmentCollection;
      await collection.doc(campaignId).update({
        'status': CampaignStatus.paused.name,
      });
      return true;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to pause campaign: $e');
      return false;
    }
  }

  /// Resume a campaign
  Future<bool> resumeCampaign(String campaignId, {bool isGrowth = false}) async {
    try {
      final collection = isGrowth ? _growthCampaignsCollection : _recruitmentCollection;
      await collection.doc(campaignId).update({
        'status': CampaignStatus.active.name,
      });
      return true;
    } catch (e) {
      debugPrint('❌ [EcosystemGrowth] Failed to resume campaign: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _campaignController.close();
    _leadController.close();
  }
}

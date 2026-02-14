/// Experiment Configuration
///
/// Defines experiment variants for A/B testing including
/// onboarding, paywall, and retention experiments.
library;

/// Variant assignment for user experiments
enum VariantAssignment {
  control,
  variantA,
  variantB,
  variantC,
}

/// Experiment status
enum ExperimentStatus {
  draft,
  running,
  paused,
  completed,
  archived,
}

/// Base experiment configuration
class ExperimentConfig {
  final String id;
  final String name;
  final String description;
  final ExperimentStatus status;
  final Map<VariantAssignment, double> trafficAllocation;
  final List<String> targetSegments;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic> defaultVariantSettings;
  final Map<VariantAssignment, Map<String, dynamic>> variantSettings;
  final List<String> primaryMetrics;
  final List<String> secondaryMetrics;
  final int minSampleSize;
  final double minConfidence;

  const ExperimentConfig({
    required this.id,
    required this.name,
    required this.description,
    this.status = ExperimentStatus.draft,
    required this.trafficAllocation,
    this.targetSegments = const [],
    required this.startDate,
    this.endDate,
    this.defaultVariantSettings = const {},
    this.variantSettings = const {},
    this.primaryMetrics = const [],
    this.secondaryMetrics = const [],
    this.minSampleSize = 1000,
    this.minConfidence = 0.95,
  });

  /// Check if experiment is active
  bool get isActive {
    final now = DateTime.now();
    final started = now.isAfter(startDate);
    final notEnded = endDate == null || now.isBefore(endDate!);
    return status == ExperimentStatus.running && started && notEnded;
  }

  /// Get settings for a specific variant
  Map<String, dynamic> getVariantSettings(VariantAssignment variant) {
    return {
      ...defaultVariantSettings,
      ...?variantSettings[variant],
    };
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'status': status.name,
    'trafficAllocation': trafficAllocation.map((k, v) => MapEntry(k.name, v)),
    'targetSegments': targetSegments,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'defaultVariantSettings': defaultVariantSettings,
    'variantSettings': variantSettings.map(
      (k, v) => MapEntry(k.name, v),
    ),
    'primaryMetrics': primaryMetrics,
    'secondaryMetrics': secondaryMetrics,
    'minSampleSize': minSampleSize,
    'minConfidence': minConfidence,
  };
}

/// ============================================================
/// ONBOARDING EXPERIMENT VARIANTS
/// ============================================================

/// Onboarding flow variants
class OnboardingVariants {
  /// Quick onboarding (3 steps)
  static const ExperimentConfig quickOnboarding = ExperimentConfig(
    id: 'onboarding_quick_v1',
    name: 'Quick Onboarding',
    description: 'Test 3-step vs 5-step onboarding flow',
    trafficAllocation: {
      VariantAssignment.control: 0.50, // 5-step standard
      VariantAssignment.variantA: 0.50, // 3-step quick
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['onboarding_completion_rate', 'time_to_first_room'],
    secondaryMetrics: ['day7_retention', 'first_session_duration'],
    variantSettings: {
      VariantAssignment.control: {
        'steps': 5,
        'showProfileSetup': true,
        'showInterestSelection': true,
        'showTutorial': true,
      },
      VariantAssignment.variantA: {
        'steps': 3,
        'showProfileSetup': true,
        'showInterestSelection': false,
        'showTutorial': false,
      },
    },
  );

  /// Social proof onboarding
  static const ExperimentConfig socialProofOnboarding = ExperimentConfig(
    id: 'onboarding_social_proof_v1',
    name: 'Social Proof Onboarding',
    description: 'Test social proof elements during onboarding',
    trafficAllocation: {
      VariantAssignment.control: 0.34,
      VariantAssignment.variantA: 0.33, // With social proof badges
      VariantAssignment.variantB: 0.33, // With live user count
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['onboarding_completion_rate', 'signup_conversion'],
    secondaryMetrics: ['perceived_trust_score', 'day1_retention'],
    variantSettings: {
      VariantAssignment.control: {
        'showSocialProof': false,
      },
      VariantAssignment.variantA: {
        'showSocialProof': true,
        'socialProofType': 'badges',
      },
      VariantAssignment.variantB: {
        'showSocialProof': true,
        'socialProofType': 'live_users',
      },
    },
  );

  /// All onboarding experiments
  static const List<ExperimentConfig> all = [
    quickOnboarding,
    socialProofOnboarding,
  ];
}

/// ============================================================
/// PAYWALL EXPERIMENT VARIANTS
/// ============================================================

/// Paywall configuration variants
class PaywallVariants {
  /// Pricing experiment
  static const ExperimentConfig pricingTiers = ExperimentConfig(
    id: 'paywall_pricing_v1',
    name: 'Pricing Tiers',
    description: 'Test different pricing structures',
    trafficAllocation: {
      VariantAssignment.control: 0.34, // Standard pricing
      VariantAssignment.variantA: 0.33, // Premium-first
      VariantAssignment.variantB: 0.33, // Value-focused
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['conversion_rate', 'revenue_per_user'],
    secondaryMetrics: ['trial_starts', 'churn_rate'],
    variantSettings: {
      VariantAssignment.control: {
        'defaultPlan': 'monthly',
        'showAnnualFirst': false,
        'discountHighlight': false,
      },
      VariantAssignment.variantA: {
        'defaultPlan': 'annual',
        'showAnnualFirst': true,
        'discountHighlight': true,
      },
      VariantAssignment.variantB: {
        'defaultPlan': 'quarterly',
        'showAnnualFirst': false,
        'discountHighlight': true,
        'showValueComparison': true,
      },
    },
  );

  /// Paywall timing experiment
  static const ExperimentConfig paywallTiming = ExperimentConfig(
    id: 'paywall_timing_v1',
    name: 'Paywall Timing',
    description: 'Test when to show paywall during user journey',
    trafficAllocation: {
      VariantAssignment.control: 0.34, // After 3 room visits
      VariantAssignment.variantA: 0.33, // After first premium feature
      VariantAssignment.variantB: 0.33, // After value demonstration
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['paywall_conversion', 'time_to_conversion'],
    secondaryMetrics: ['user_drop_off', 'feature_adoption'],
    variantSettings: {
      VariantAssignment.control: {
        'triggerType': 'room_visits',
        'triggerThreshold': 3,
      },
      VariantAssignment.variantA: {
        'triggerType': 'premium_feature_attempt',
        'triggerThreshold': 1,
      },
      VariantAssignment.variantB: {
        'triggerType': 'value_events',
        'triggerThreshold': 5,
        'valueEvents': ['match_made', 'gift_received', 'vip_interaction'],
      },
    },
  );

  /// Free trial length experiment
  static const ExperimentConfig trialLength = ExperimentConfig(
    id: 'paywall_trial_v1',
    name: 'Trial Length',
    description: 'Test different free trial durations',
    trafficAllocation: {
      VariantAssignment.control: 0.34, // 7 days
      VariantAssignment.variantA: 0.33, // 3 days
      VariantAssignment.variantB: 0.33, // 14 days
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['trial_to_paid', 'trial_engagement'],
    secondaryMetrics: ['trial_churn_day', 'feature_usage_in_trial'],
    variantSettings: {
      VariantAssignment.control: {'trialDays': 7},
      VariantAssignment.variantA: {'trialDays': 3},
      VariantAssignment.variantB: {'trialDays': 14},
    },
  );

  /// All paywall experiments
  static const List<ExperimentConfig> all = [
    pricingTiers,
    paywallTiming,
    trialLength,
  ];
}

/// ============================================================
/// RETENTION EXPERIMENT VARIANTS
/// ============================================================

/// Retention campaign variants
class RetentionVariants {
  /// Push notification frequency
  static const ExperimentConfig notificationFrequency = ExperimentConfig(
    id: 'retention_notif_freq_v1',
    name: 'Notification Frequency',
    description: 'Test optimal push notification frequency',
    trafficAllocation: {
      VariantAssignment.control: 0.25, // Daily
      VariantAssignment.variantA: 0.25, // Every other day
      VariantAssignment.variantB: 0.25, // Weekly digest
      VariantAssignment.variantC: 0.25, // Smart timing
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['day7_retention', 'day30_retention'],
    secondaryMetrics: ['notification_open_rate', 'unsubscribe_rate', 'dau'],
    variantSettings: {
      VariantAssignment.control: {
        'frequency': 'daily',
        'maxPerDay': 3,
      },
      VariantAssignment.variantA: {
        'frequency': 'alternate',
        'maxPerDay': 2,
      },
      VariantAssignment.variantB: {
        'frequency': 'weekly',
        'digestDay': 'sunday',
      },
      VariantAssignment.variantC: {
        'frequency': 'smart',
        'useMLTiming': true,
      },
    },
  );

  /// Win-back campaign
  static const ExperimentConfig winbackCampaign = ExperimentConfig(
    id: 'retention_winback_v1',
    name: 'Win-back Campaign',
    description: 'Test win-back message strategies for churned users',
    trafficAllocation: {
      VariantAssignment.control: 0.34, // Generic "we miss you"
      VariantAssignment.variantA: 0.33, // Personalized with stats
      VariantAssignment.variantB: 0.33, // Offer-based incentive
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['reactivation_rate', 'post_winback_retention'],
    secondaryMetrics: ['email_open_rate', 'app_reinstall_rate'],
    variantSettings: {
      VariantAssignment.control: {
        'messageType': 'generic',
        'includeOffer': false,
      },
      VariantAssignment.variantA: {
        'messageType': 'personalized',
        'includeStats': true,
        'includeOffer': false,
      },
      VariantAssignment.variantB: {
        'messageType': 'incentive',
        'includeOffer': true,
        'offerType': 'free_premium_day',
      },
    },
  );

  /// Engagement hooks
  static const ExperimentConfig engagementHooks = ExperimentConfig(
    id: 'retention_hooks_v1',
    name: 'Engagement Hooks',
    description: 'Test different engagement mechanics',
    trafficAllocation: {
      VariantAssignment.control: 0.34, // Standard
      VariantAssignment.variantA: 0.33, // Streaks
      VariantAssignment.variantB: 0.33, // Daily challenges
    },
    startDate: _experimentStartDate,
    primaryMetrics: ['daily_active_users', 'session_frequency'],
    secondaryMetrics: ['feature_completion', 'social_actions'],
    variantSettings: {
      VariantAssignment.control: {
        'hooks': [],
      },
      VariantAssignment.variantA: {
        'hooks': ['daily_streak'],
        'streakBonusCoins': [10, 20, 50, 100, 200],
      },
      VariantAssignment.variantB: {
        'hooks': ['daily_challenge'],
        'challengeTypes': ['visit_room', 'send_gift', 'add_friend'],
      },
    },
  );

  /// All retention experiments
  static const List<ExperimentConfig> all = [
    notificationFrequency,
    winbackCampaign,
    engagementHooks,
  ];
}

/// ============================================================
/// ALL EXPERIMENTS REGISTRY
/// ============================================================

/// Central registry of all experiments
class ExperimentRegistry {
  /// All active experiments by ID
  static final Map<String, ExperimentConfig> experiments = {
    for (final exp in [
      ...OnboardingVariants.all,
      ...PaywallVariants.all,
      ...RetentionVariants.all,
    ])
      exp.id: exp,
  };

  /// Get experiment by ID
  static ExperimentConfig? getExperiment(String id) => experiments[id];

  /// Get all experiments for a category
  static List<ExperimentConfig> getByCategory(String category) {
    switch (category) {
      case 'onboarding':
        return OnboardingVariants.all;
      case 'paywall':
        return PaywallVariants.all;
      case 'retention':
        return RetentionVariants.all;
      default:
        return [];
    }
  }

  /// Get all active experiments
  static List<ExperimentConfig> get activeExperiments =>
      experiments.values.where((e) => e.isActive).toList();
}

// Placeholder date - actual experiments should use proper dates
const _experimentStartDate = _PlaceholderDate();

class _PlaceholderDate implements DateTime {
  const _PlaceholderDate();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Default to experiment start date being in the past
    final now = DateTime.now();
    return now.subtract(const Duration(days: 30));
  }
}

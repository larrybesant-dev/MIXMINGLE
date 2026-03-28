enum AdultRelationshipIntent {
  love,
  fun,
  hookups,
  openConnection,
}

enum AdultProfileVisibility {
  optedInAdultsOnly,
  privateOnly,
}

class AdultProfileModel {
  const AdultProfileModel({
    required this.userId,
    this.enabled = false,
    this.adultConsentAccepted = false,
    this.visibility = AdultProfileVisibility.optedInAdultsOnly,
    this.kinks = const [],
    this.preferences = const [],
    this.boundaries = const [],
    this.lookingFor = const [],
    this.updatedAt,
  });

  final String userId;
  final bool enabled;
  final bool adultConsentAccepted;
  final AdultProfileVisibility visibility;
  final List<String> kinks;
  final List<String> preferences;
  final List<String> boundaries;
  final List<AdultRelationshipIntent> lookingFor;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enabled': enabled,
      'adultConsentAccepted': adultConsentAccepted,
      'visibility': visibility.name,
      'kinks': kinks,
      'preferences': preferences,
      'boundaries': boundaries,
      'lookingFor': lookingFor.map((item) => item.name).toList(growable: false),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AdultProfileModel.fromJson(Map<String, dynamic> json) {
    return AdultProfileModel(
      userId: json['userId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      adultConsentAccepted: json['adultConsentAccepted'] as bool? ?? false,
      visibility: AdultProfileVisibility.values.firstWhere(
        (value) => value.name == json['visibility'],
        orElse: () => AdultProfileVisibility.optedInAdultsOnly,
      ),
      kinks: List<String>.from(json['kinks'] ?? const []),
      preferences: List<String>.from(json['preferences'] ?? const []),
      boundaries: List<String>.from(json['boundaries'] ?? const []),
      lookingFor: List<String>.from(json['lookingFor'] ?? const [])
          .map(
            (value) => AdultRelationshipIntent.values.firstWhere(
              (item) => item.name == value,
              orElse: () => AdultRelationshipIntent.fun,
            ),
          )
          .toList(growable: false),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
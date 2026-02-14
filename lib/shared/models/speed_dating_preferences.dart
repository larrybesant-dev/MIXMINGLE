/// Speed Dating Preferences Model
/// Comprehensive matching preferences for video speed dating
library;


class SpeedDatingPreferences {
  final int minAge;
  final int maxAge;
  final int maxDistance; // miles
  final List<String> genderPreferences;
  final List<String> sexuality;
  final List<String> relationshipStyle;
  final List<String> kinks;
  final String? hasKids; // 'yes', 'no', 'open'
  final int? minHeight; // inches
  final int? maxHeight; // inches
  final List<String>? races; // Optional race preferences
  final bool onlyVerified; // Only match with verified users

  const SpeedDatingPreferences({
    required this.minAge,
    required this.maxAge,
    required this.maxDistance,
    required this.genderPreferences,
    this.sexuality = const [],
    this.relationshipStyle = const [],
    this.kinks = const [],
    this.hasKids,
    this.minHeight,
    this.maxHeight,
    this.races,
    this.onlyVerified = false,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'genderPreferences': genderPreferences,
      'sexuality': sexuality,
      'relationshipStyle': relationshipStyle,
      'kinks': kinks,
      'hasKids': hasKids,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'races': races,
      'onlyVerified': onlyVerified,
    };
  }

  /// Create from Firestore document
  factory SpeedDatingPreferences.fromMap(Map<String, dynamic> map) {
    return SpeedDatingPreferences(
      minAge: map['minAge'] as int? ?? 18,
      maxAge: map['maxAge'] as int? ?? 99,
      maxDistance: map['maxDistance'] as int? ?? 50,
      genderPreferences: List<String>.from(map['genderPreferences'] ?? []),
      sexuality: List<String>.from(map['sexuality'] ?? []),
      relationshipStyle: List<String>.from(map['relationshipStyle'] ?? []),
      kinks: List<String>.from(map['kinks'] ?? []),
      hasKids: map['hasKids'] as String?,
      minHeight: map['minHeight'] as int?,
      maxHeight: map['maxHeight'] as int?,
      races: map['races'] != null ? List<String>.from(map['races']) : null,
      onlyVerified: map['onlyVerified'] as bool? ?? false,
    );
  }

  /// Default preferences for new users
  factory SpeedDatingPreferences.defaultPreferences() {
    return const SpeedDatingPreferences(
      minAge: 18,
      maxAge: 35,
      maxDistance: 50,
      genderPreferences: ['Any'],
      sexuality: [],
      relationshipStyle: [],
      kinks: [],
      hasKids: 'open',
      onlyVerified: false,
    );
  }

  SpeedDatingPreferences copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? genderPreferences,
    List<String>? sexuality,
    List<String>? relationshipStyle,
    List<String>? kinks,
    String? hasKids,
    int? minHeight,
    int? maxHeight,
    List<String>? races,
    bool? onlyVerified,
  }) {
    return SpeedDatingPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      genderPreferences: genderPreferences ?? this.genderPreferences,
      sexuality: sexuality ?? this.sexuality,
      relationshipStyle: relationshipStyle ?? this.relationshipStyle,
      kinks: kinks ?? this.kinks,
      hasKids: hasKids ?? this.hasKids,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      races: races ?? this.races,
      onlyVerified: onlyVerified ?? this.onlyVerified,
    );
  }
}

/// Available options for preferences

class PreferenceOptions {
  static const List<String> genderOptions = [
    'Men',
    'Women',
    'Non-binary',
    'Any',
  ];

  static const List<String> sexualityOptions = [
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Pansexual',
    'Asexual',
    'Queer',
  ];

  static const List<String> relationshipStyleOptions = [
    'Monogamous',
    'Polyamorous',
    'Open Relationship',
    'Casual Dating',
    'Serious Relationship',
    'Friends with Benefits',
    'Just Friends',
  ];

  static const List<String> kinkOptions = [
    'BDSM',
    'Roleplay',
    'Voyeurism',
    'Exhibitionism',
    'Dominant',
    'Submissive',
    'Switch',
    'Vanilla',
  ];

  static const List<String> kidsOptions = [
    'yes',
    'no',
    'open',
  ];

  static const List<String> raceOptions = [
    'Asian',
    'Black',
    'Hispanic/Latino',
    'Middle Eastern',
    'Native American',
    'Pacific Islander',
    'White',
    'Mixed',
    'Other',
  ];
}

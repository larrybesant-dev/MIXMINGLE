library;

class DiscoveryFilters {
  final int minAge;
  final int maxAge;
  final int maxDistance; // miles
  final List<String> genders;
  final List<String>? races;
  final List<String>? sexualities;
  final List<String>? relationshipStyles;
  final List<String>? kinks;
  final String? hasKids; // 'yes', 'no', 'open', null = no filter
  final int? minHeight; // inches
  final int? maxHeight; // inches
  final bool onlyVerified;
  final bool onlyPremium; // Premium-only filter
  final bool onlyOnline;

  const DiscoveryFilters({
    this.minAge = 18,
    this.maxAge = 99,
    this.maxDistance = 100,
    this.genders = const ['Any'],
    this.races,
    this.sexualities,
    this.relationshipStyles,
    this.kinks,
    this.hasKids,
    this.minHeight,
    this.maxHeight,
    this.onlyVerified = false,
    this.onlyPremium = false,
    this.onlyOnline = false,
  });

  /// Check if a filter is a premium filter (requires payment)
  bool get hasPremiumFilters =>
      races != null ||
      sexualities != null ||
      relationshipStyles != null ||
      kinks != null ||
      hasKids != null ||
      minHeight != null ||
      maxHeight != null ||
      onlyPremium;

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'genders': genders,
      'races': races,
      'sexualities': sexualities,
      'relationshipStyles': relationshipStyles,
      'kinks': kinks,
      'hasKids': hasKids,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'onlyVerified': onlyVerified,
      'onlyPremium': onlyPremium,
      'onlyOnline': onlyOnline,
    };
  }

  /// Create from map
  factory DiscoveryFilters.fromMap(Map<String, dynamic> map) {
    return DiscoveryFilters(
      minAge: map['minAge'] as int? ?? 18,
      maxAge: map['maxAge'] as int? ?? 99,
      maxDistance: map['maxDistance'] as int? ?? 100,
      genders: List<String>.from(map['genders'] ?? ['Any']),
      races: map['races'] != null ? List<String>.from(map['races']) : null,
      sexualities: map['sexualities'] != null
          ? List<String>.from(map['sexualities'])
          : null,
      relationshipStyles: map['relationshipStyles'] != null
          ? List<String>.from(map['relationshipStyles'])
          : null,
      kinks: map['kinks'] != null ? List<String>.from(map['kinks']) : null,
      hasKids: map['hasKids'] as String?,
      minHeight: map['minHeight'] as int?,
      maxHeight: map['maxHeight'] as int?,
      onlyVerified: map['onlyVerified'] as bool? ?? false,
      onlyPremium: map['onlyPremium'] as bool? ?? false,
      onlyOnline: map['onlyOnline'] as bool? ?? false,
    );
  }

  /// Default filters
  factory DiscoveryFilters.defaultFilters() {
    return const DiscoveryFilters();
  }

  DiscoveryFilters copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? genders,
    List<String>? races,
    List<String>? sexualities,
    List<String>? relationshipStyles,
    List<String>? kinks,
    String? hasKids,
    int? minHeight,
    int? maxHeight,
    bool? onlyVerified,
    bool? onlyPremium,
    bool? onlyOnline,
  }) {
    return DiscoveryFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      genders: genders ?? this.genders,
      races: races ?? this.races,
      sexualities: sexualities ?? this.sexualities,
      relationshipStyles: relationshipStyles ?? this.relationshipStyles,
      kinks: kinks ?? this.kinks,
      hasKids: hasKids ?? this.hasKids,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyPremium: onlyPremium ?? this.onlyPremium,
      onlyOnline: onlyOnline ?? this.onlyOnline,
    );
  }
}

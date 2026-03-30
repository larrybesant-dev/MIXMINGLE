class ProfilePrivacyModel {
  const ProfilePrivacyModel({
    this.showAge = false,
    this.showGender = false,
    this.showLocation = false,
    this.showRelationshipStatus = false,
  });

  final bool showAge;
  final bool showGender;
  final bool showLocation;
  final bool showRelationshipStatus;

  Map<String, dynamic> toJson() {
    return {
      'showAge': showAge,
      'showGender': showGender,
      'showLocation': showLocation,
      'showRelationshipStatus': showRelationshipStatus,
    };
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  factory ProfilePrivacyModel.fromJson(Map<String, dynamic>? json) {
    return ProfilePrivacyModel(
      showAge: _asBool(json?['showAge']),
      showGender: _asBool(json?['showGender']),
      showLocation: _asBool(json?['showLocation']),
      showRelationshipStatus: _asBool(json?['showRelationshipStatus']),
    );
  }

  ProfilePrivacyModel copyWith({
    bool? showAge,
    bool? showGender,
    bool? showLocation,
    bool? showRelationshipStatus,
  }) {
    return ProfilePrivacyModel(
      showAge: showAge ?? this.showAge,
      showGender: showGender ?? this.showGender,
      showLocation: showLocation ?? this.showLocation,
      showRelationshipStatus: showRelationshipStatus ?? this.showRelationshipStatus,
    );
  }
}
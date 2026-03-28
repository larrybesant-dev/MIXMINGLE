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

  factory ProfilePrivacyModel.fromJson(Map<String, dynamic>? json) {
    return ProfilePrivacyModel(
      showAge: json?['showAge'] as bool? ?? false,
      showGender: json?['showGender'] as bool? ?? false,
      showLocation: json?['showLocation'] as bool? ?? false,
      showRelationshipStatus: json?['showRelationshipStatus'] as bool? ?? false,
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
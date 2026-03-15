// UserProfile model for MIXVY social features
class UserProfile {
  final String id;
  final String displayName;
  final String avatarUrl;
  final String bio;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
  });

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final List<String> interests;
  final List<String> prompts;
  final List<String> gallery;
  final String vibe;
  final bool isOnline;
  final DateTime? lastActive;
  final String onboardingState;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.interests,
    required this.prompts,
    required this.gallery,
    required this.vibe,
    required this.isOnline,
    required this.lastActive,
    required this.onboardingState,
  });

  factory UserModel.empty(String id) {
    return UserModel(
      id: id,
      username: '',
      displayName: '',
      avatarUrl: '',
      bio: '',
      interests: const [],
      prompts: const [],
      gallery: const [],
      vibe: '',
      isOnline: false,
      lastActive: null,
      onboardingState: 'not_started',
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      prompts: List<String>.from(data['prompts'] ?? []),
      gallery: List<String>.from(data['gallery'] ?? []),
      vibe: data['vibe'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      onboardingState: data['onboardingState'] ?? 'not_started',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'interests': interests,
      'prompts': prompts,
      'gallery': gallery,
      'vibe': vibe,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'onboardingState': onboardingState,
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    List<String>? prompts,
    List<String>? gallery,
    String? vibe,
    bool? isOnline,
    DateTime? lastActive,
    String? onboardingState,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts,
      gallery: gallery ?? this.gallery,
      vibe: vibe ?? this.vibe,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      onboardingState: onboardingState ?? this.onboardingState,
    );
  }
}

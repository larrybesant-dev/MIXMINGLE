class UserStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final int totalDaysActive;
  final Map<String, int> rewardsEarned; // date -> coins earned

  UserStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.totalDaysActive,
    required this.rewardsEarned,
  });

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    return UserStreak(
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.parse(map['lastActiveDate'])
          : DateTime.now(),
      totalDaysActive: map['totalDaysActive'] ?? 0,
      rewardsEarned: Map<String, int>.from(map['rewardsEarned'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'totalDaysActive': totalDaysActive,
      'rewardsEarned': rewardsEarned,
    };
  }

  // Calculate daily reward based on streak
  int get dailyReward {
    if (currentStreak >= 30) return 15; // Month+
    if (currentStreak >= 14) return 10; // 2 weeks
    if (currentStreak >= 7) return 7; // Week
    if (currentStreak >= 3) return 5; // 3 days
    return 3; // Base reward
  }

  bool get canClaimToday {
    final today = DateTime.now();
    final lastActive = lastActiveDate;
    return today.year != lastActive.year ||
        today.month != lastActive.month ||
        today.day != lastActive.day;
  }

  UserStreak copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalDaysActive,
    Map<String, int>? rewardsEarned,
  }) {
    return UserStreak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      rewardsEarned: rewardsEarned ?? this.rewardsEarned,
    );
  }
}

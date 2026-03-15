class UserLevel {
  final String userId;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final DateTime lastUpdated;

  UserLevel({
    required this.userId,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.lastUpdated,
  });

  // Backward compatibility getter
  int get currentXP => xp;

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    return UserLevel(
      userId: map['userId'] ?? '',
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      xpToNextLevel: map['xpToNextLevel'] ?? 100,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'level': level,
      'xp': xp,
      'xpToNextLevel': xpToNextLevel,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Calculate XP required for next level (exponential growth)
  static int calculateXPForLevel(int level) {
    return (100 * level * 1.5).round();
  }

  // Calculate level from total XP
  static int calculateLevelFromXP(int totalXP) {
    int level = 1;
    int xpRequired = 100;
    int accumulatedXP = 0;

    while (accumulatedXP + xpRequired <= totalXP) {
      accumulatedXP += xpRequired;
      level++;
      xpRequired = calculateXPForLevel(level);
    }

    return level;
  }

  double get progressPercentage => xp / xpToNextLevel;

  String get levelTitle {
    if (level >= 50) return 'Legend';
    if (level >= 40) return 'Master';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Veteran';
    if (level >= 10) return 'Regular';
    if (level >= 5) return 'Member';
    return 'Newbie';
  }

  UserLevel copyWith({
    String? userId,
    int? level,
    int? xp,
    int? xpToNextLevel,
    DateTime? lastUpdated,
  }) {
    return UserLevel(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

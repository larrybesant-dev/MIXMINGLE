class User {
  final String id;
  final String username;
  final String avatarUrl;
  final int coinBalance;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.coinBalance,
  });

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asString(json['id']),
      username: _asString(json['username']),
      avatarUrl: _asString(json['avatarUrl']),
      coinBalance: ((json['balance'] ?? json['coinBalance']) as num?)?.toInt() ?? 0,
    );
  }
}

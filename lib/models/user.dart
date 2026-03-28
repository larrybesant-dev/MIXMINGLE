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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      coinBalance: ((json['balance'] ?? json['coinBalance']) as num?)?.toInt() ?? 0,
    );
  }
}

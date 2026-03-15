// Connection model for MIXVY social features
class Connection {
  final String id;
  final String userId;
  final String status; // pending, accepted, blocked

  Connection({
    required this.id,
    required this.userId,
    required this.status,
  });

  Connection copyWith({
    String? status,
  }) {
    return Connection(
      id: id,
      userId: userId,
      status: status ?? this.status,
    );
  }
}

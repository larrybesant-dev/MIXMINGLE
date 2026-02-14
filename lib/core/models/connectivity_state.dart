class ConnectivityState {
  final bool isOnline;
  final String? errorMessage;
  final DateTime? lastOfflineAt;

  const ConnectivityState({
    required this.isOnline,
    this.errorMessage,
    this.lastOfflineAt,
  });

  factory ConnectivityState.online() => const ConnectivityState(isOnline: true);

  factory ConnectivityState.offline(String? message) => ConnectivityState(
        isOnline: false,
        errorMessage: message,
        lastOfflineAt: DateTime.now(),
      );

  ConnectivityState copyWith({
    bool? isOnline,
    String? errorMessage,
    DateTime? lastOfflineAt,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      errorMessage: errorMessage ?? this.errorMessage,
      lastOfflineAt: lastOfflineAt ?? this.lastOfflineAt,
    );
  }
}

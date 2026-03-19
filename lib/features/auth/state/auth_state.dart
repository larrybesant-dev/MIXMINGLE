class AuthState {
  final bool isLoading;
  final String? error;
  final String? uid;

  AuthState({
    this.isLoading = false,
    this.error,
    this.uid,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? uid,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      uid: uid ?? this.uid,
    );
  }
}

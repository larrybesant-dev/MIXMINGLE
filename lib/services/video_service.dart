class VideoService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> initializeClient({
    required String channelName,
    required String userId,
    required bool isBroadcaster,
  }) async {
    // Mock implementation - no actual video functionality
  }

  Future<void> joinChannel() async {
    // Mock implementation - no actual video functionality
  }

  Future<void> dispose() async {
    // Mock implementation - no actual video functionality
  }

  dynamic get client => null; // Return null since we don't have a real client
}



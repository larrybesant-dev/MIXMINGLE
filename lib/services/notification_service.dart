class NotificationService {
	Future<void> pushNotification(String userId, String message) async {
		// Implement push notification logic
		await Future.delayed(Duration(milliseconds: 500));
	}

	Future<void> inAppNotification(String userId, String message) async {
		// Implement in-app notification logic
		await Future.delayed(Duration(milliseconds: 500));
	}
}

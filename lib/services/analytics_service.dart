import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logPurchase({required double value, String? currency}) async {
    await _analytics.logEvent(name: 'purchase', parameters: {
      'value': value,
      'currency': currency ?? 'usd',
    });
  }

  Future<void> logViewItem({required String itemId, String? itemName}) async {
    await _analytics.logEvent(name: 'view_item', parameters: {
      'item_id': itemId,
      'item_name': itemName,
    });
  }
}

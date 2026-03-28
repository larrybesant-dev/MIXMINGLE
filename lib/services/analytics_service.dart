import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics}) : _analytics = analytics;

  FirebaseAnalytics? _analytics;

  FirebaseAnalytics? _resolveAnalytics() {
    if (_analytics != null) {
      return _analytics;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }

    return _analytics;
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    final analytics = _resolveAnalytics();
    if (analytics == null) {
      return;
    }
    await analytics.logEvent(name: name, parameters: params);
  }

  Future<void> logLogin({String? method}) async {
    final analytics = _resolveAnalytics();
    if (analytics == null) {
      return;
    }
    await analytics.logLogin(loginMethod: method);
  }

  Future<void> logPurchase({required double value, String? currency}) async {
    final analytics = _resolveAnalytics();
    if (analytics == null) {
      return;
    }
    await analytics.logEvent(name: 'purchase', parameters: <String, Object>{
      'value': value,
      'currency': currency ?? 'usd',
    });
  }

  Future<void> logViewItem({required String itemId, String? itemName}) async {
    final analytics = _resolveAnalytics();
    if (analytics == null) {
      return;
    }
    await analytics.logEvent(name: 'view_item', parameters: <String, Object>{
      'item_id': itemId,
      'item_name': itemName ?? '',
    });
  }
}

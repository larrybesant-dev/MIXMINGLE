import 'dart:async';
import 'dart:collection';

import '../../features/feed/services/home_feed_service.dart';
import '../../services/notification_service.dart';
import '../../services/social_activity_service.dart';
import 'app_event.dart';
import 'app_event_bus.dart';

class EventPipeline {
  EventPipeline({
    required this.eventBus,
    required this.socialActivityService,
    required this.notificationService,
    HomeFeedService? homeFeedService,
  }) : homeFeedService = homeFeedService ?? const HomeFeedService();

  final AppEventBus eventBus;
  final SocialActivityService socialActivityService;
  final NotificationService notificationService;
  final HomeFeedService homeFeedService;

  final Queue<String> _recentEventIds = Queue<String>();
  final Set<String> _dedupeIds = <String>{};
  StreamSubscription<AppEvent>? _subscription;

  void start() {
    _subscription ??= eventBus.stream.listen((event) async {
      if (!_markSeen(event.id)) {
        return;
      }
      try {
        await _route(event);
      } catch (_) {
        // Keep the pipeline alive even if one consumer fails.
      }
    });
  }

  Future<void> _route(AppEvent event) async {
    homeFeedService.handle(event);
    await socialActivityService.handleEvent(event);
    await notificationService.handleEvent(event);
  }

  bool _markSeen(String eventId) {
    final normalizedId = eventId.trim();
    if (normalizedId.isEmpty) {
      return true;
    }
    if (_dedupeIds.contains(normalizedId)) {
      return false;
    }
    _dedupeIds.add(normalizedId);
    _recentEventIds.addLast(normalizedId);
    while (_recentEventIds.length > 256) {
      final removed = _recentEventIds.removeFirst();
      _dedupeIds.remove(removed);
    }
    return true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

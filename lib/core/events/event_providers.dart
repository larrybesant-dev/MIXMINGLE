import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/feed/services/home_feed_service.dart';
import '../../services/notification_service.dart';
import '../../services/social_activity_service.dart';
import '../providers/firebase_providers.dart';
import 'app_event_bus.dart';
import 'event_pipeline.dart';

final appEventBusProvider = Provider<AppEventBus>((ref) {
  return AppEventBus.instance;
});

final eventPipelineProvider = Provider<EventPipeline>((ref) {
  final pipeline = EventPipeline(
    eventBus: ref.watch(appEventBusProvider),
    socialActivityService: SocialActivityService(
      firestore: ref.watch(firestoreProvider),
    ),
    notificationService: NotificationService(
      firestore: ref.watch(firestoreProvider),
    ),
    homeFeedService: const HomeFeedService(),
  )..start();

  ref.onDispose(() {
    pipeline.dispose();
  });

  return pipeline;
});

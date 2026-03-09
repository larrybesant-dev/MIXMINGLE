import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feed_service.dart';

final feedProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return await FeedService().getFeed(userId);
});

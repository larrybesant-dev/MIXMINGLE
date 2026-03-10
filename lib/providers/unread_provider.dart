import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/providers/all_providers.dart';
import '../services/messaging_service.dart';

final unreadCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentUserProfileProvider).value;
  if (currentUser == null) {
    return const Stream.empty();
  }

  final messaging = ref.watch(messagingServiceProvider);

  return messaging.streamConversations(currentUser.id).map((convos) {
    int total = 0;
    for (final c in convos) {
      final unread = ((c['unread'][currentUser.id] ?? 0) as num).toInt();
      total += unread;
    }
    return total;
  });
});

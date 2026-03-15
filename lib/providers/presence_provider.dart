import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/presence_service.dart';

final presenceProvider = StreamProvider.family<bool, String>((ref, userId) {
  return PresenceService().streamPresence(userId);
});

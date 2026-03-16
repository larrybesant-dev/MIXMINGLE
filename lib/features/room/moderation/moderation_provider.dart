import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/moderation_service.dart';

final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService();
});

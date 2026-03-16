import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/presence_service.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/follow_service.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService();
});

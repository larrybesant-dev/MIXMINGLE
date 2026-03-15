import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../models/user_profile_model.dart';

final profileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  return ProfileService().streamProfile(userId);
});

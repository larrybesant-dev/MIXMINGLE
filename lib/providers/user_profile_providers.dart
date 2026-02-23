// lib/providers/user_profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) => UserProfileService());
final userProfileProvider = Provider.family<UserProfileModel?, String>((ref, userId) => ref.read(userProfileServiceProvider).getProfile(userId));

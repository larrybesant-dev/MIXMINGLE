import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/models/user_profile.dart';

final currentUserProfileProvider = StateProvider<UserProfile?>((ref) => null);

import 'package:mixmingle/models/user_profile.dart';

extension UserProfileAdapters on UserProfile {
  String get safeId => uid;
  String get safeDisplayName => displayNameOrNickname;
  String get safeLocation => location ?? '';
  String get safeCountryCode => countryCode ?? '';
}

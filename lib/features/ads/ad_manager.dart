// AdManager handles ad display and user preferences
class AdManager {
  // Show popup ad if user is free
  static bool shouldShowAds(String membershipLevel) {
    return membershipLevel == 'Free';
  }
}

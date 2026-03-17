// AdManager handles ad display and user preferences
class AdManager {
  // Show popup ad if user is free
  static bool shouldShowAds(String membershipLevel) {
    return membershipLevel == 'Free';
  }

  // Display ad popup logic
  static void showAdPopup(context) {
    // TODO: Implement ad popup UI
  }
}

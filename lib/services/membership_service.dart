class MembershipService {
  String currentUserId = '';
  int coinBalance = 0;
  String membershipLevel = 'Free';
  double spotlightMultiplier = 1.0;

  void setMembership(String level) {
    membershipLevel = level;
    switch (level) {
      case 'Silver':
        spotlightMultiplier = 1.2;
        break;
      case 'Gold':
        spotlightMultiplier = 1.5;
        break;
      case 'Platinum':
        spotlightMultiplier = 2.0;
        break;
      default:
        spotlightMultiplier = 1.0;
    }
  }
}

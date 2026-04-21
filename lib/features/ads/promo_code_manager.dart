// Handles promo codes for free ad spots
class PromoCodeManager {
  // Validate promo code against Firestore — NOT YET IMPLEMENTED
  static Future<bool> validatePromoCode(String code) async {
    throw UnimplementedError(
      'validatePromoCode must be backed by a Firestore collection or '
      'Cloud Function before shipping. Hardcoded codes have been removed.',
    );
  }

  // Grant free ad spot for 30 days — NOT YET IMPLEMENTED
  static Future<void> grantFreeAd(String businessId) async {
    throw UnimplementedError(
      'grantFreeAd must write to Firestore and be validated server-side.',
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class DigitalGoodsService {
  final FirebaseFirestore firestore;

  DigitalGoodsService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Purchase a pack (backend-only, Stripe webhook)
  Future<void> recordPurchase({
    required String userId,
    required UserPurchase purchase,
  }) async {
    await firestore
      .collection('users')
      .doc(userId)
      .collection('purchases')
      .doc(purchase.packId)
      .set(purchase.toJson());
  }

  // Create a user creation
  Future<void> createUserCreation({
    required String userId,
    required UserCreation creation,
  }) async {
    await firestore
      .collection('users')
      .doc(userId)
      .collection('creations')
      .doc(creation.id)
      .set(creation.toJson());
  }

  // Publish a creation as a pack (creator pro only)
  Future<void> publishCreation({
    required String creationId,
    required Map<String, dynamic> publishData,
  }) async {
    await firestore
      .collection('publish')
      .doc(creationId)
      .set(publishData);
  }
}

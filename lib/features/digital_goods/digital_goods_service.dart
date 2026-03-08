import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class DigitalGoodsService {
  final FirebaseFirestore firestore;

  DigitalGoodsService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Methods removed due to undefined types UserPurchase and UserCreation.

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

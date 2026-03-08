import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class DigitalGoodsPublishService {
  final FirebaseFirestore firestore;

  DigitalGoodsPublishService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> publishCreationAsPack({
    required String creationId,
    required Pack pack,
  }) async {
    await firestore.collection('publish').doc(creationId).set(pack.toJson());
  }
}

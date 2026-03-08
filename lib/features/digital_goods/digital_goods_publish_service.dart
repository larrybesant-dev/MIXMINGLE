import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class DigitalGoodsPublishService {
  final FirebaseFirestore firestore;

  DigitalGoodsPublishService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Method removed due to undefined Pack type.
}

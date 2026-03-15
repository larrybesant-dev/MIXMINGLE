import '../models/gift_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftService {
  final _giftsRef = FirebaseFirestore.instance.collection('gifts');

  Future<void> addGift(Gift gift) async {
    await _giftsRef.doc(gift.id).set(gift.toMap());
  }

  Stream<List<Gift>> streamGifts() {
    return _giftsRef.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Gift.fromMap(doc.data())).toList());
  }
}

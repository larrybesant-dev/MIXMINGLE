import '../models/user_wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final _walletsRef = FirebaseFirestore.instance.collection('wallets');

  Future<void> updateWallet(UserWallet wallet) async {
    await _walletsRef.doc(wallet.userId).set(wallet.toMap());
  }

  Future<UserWallet?> getWallet(String userId) async {
    final doc = await _walletsRef.doc(userId).get();
    if (doc.exists) {
      return UserWallet.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserWallet?> streamWallet(String userId) {
    return _walletsRef.doc(userId).snapshots().map((doc) =>
      doc.exists ? UserWallet.fromFirestore(doc) : null);
  }
}

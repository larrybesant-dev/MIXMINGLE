import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> purchaseCoins(int amount) async {
    await _functions.httpsCallable('purchaseCoins').call({'amount': amount});
  }

  Future<void> purchaseMembership(String tier) async {
    await _functions.httpsCallable('purchaseMembership').call({'tier': tier});
  }
}

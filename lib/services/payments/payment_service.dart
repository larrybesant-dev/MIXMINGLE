import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  final HttpsCallable processTip = FirebaseFunctions.instance.httpsCallable('processTip');
  final HttpsCallable createCheckout = FirebaseFunctions.instance.httpsCallable('createCheckout');

  Future<void> tipUser(String fromUid, String toUid, int amount) async {
    await processTip.call({'fromUid': fromUid, 'toUid': toUid, 'amount': amount});
  }

  Future<String> purchaseCoins(String uid, int amount) async {
    final result = await createCheckout.call({'uid': uid, 'amount': amount});
    return result.data['checkoutUrl'];
  }

  // Additional payment methods
  Future<void> addCoins(String uid, int amount) async {
    await createCheckout.call({'uid': uid, 'amount': amount});
  }

  Future<List<dynamic>> getPaymentMethods(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getPaymentMethods');
      final result = await callable.call({'uid': uid});
      return result.data as List<dynamic>? ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getPaymentHistory(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getPaymentHistory');
      final result = await callable.call({'uid': uid});
      return result.data as List<dynamic>? ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> processPayment(String uid, String paymentMethodId, int amount) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('processPayment');
      await callable.call({'uid': uid, 'paymentMethodId': paymentMethodId, 'amount': amount});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addPaymentMethod(String uid, Map<String, dynamic> paymentData) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addPaymentMethod');
      await callable.call({'uid': uid, ...paymentData});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removePaymentMethod(String uid, String paymentMethodId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('removePaymentMethod');
      await callable.call({'uid': uid, 'paymentMethodId': paymentMethodId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refundPayment(String uid, String transactionId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('refundPayment');
      await callable.call({'uid': uid, 'transactionId': transactionId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<int> coinBalanceStream(String uid) {
    return Stream.value(0);
  }
}



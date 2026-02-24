import 'package:cloud_functions/cloud_functions.dart';
import '../../shared/models/tip.dart';

class TippingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> sendTip(Tip tip) async {
    try {
      final result = await _functions.httpsCallable('sendTip').call({
        'receiverId': tip.receiverId,
        'amount': tip.amount,
        'message': tip.message,
        'roomId': tip.roomId,
      });

      if (result.data['success'] != true) {
        throw Exception('Tip failed');
      }
    } catch (e) {
      throw Exception('Failed to send tip: $e');
    }
  }

  Future<int> getUserBalance(String userId) async {
    try {
      final result = await _functions.httpsCallable('getUserBalance').call({
        'userId': userId,
      });
      return result.data['balance'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> addCoins(String userId, int amount) async {
    try {
      await _functions.httpsCallable('addCoins').call({
        'userId': userId,
        'amount': amount,
      });
    } catch (e) {
      throw Exception('Failed to add coins: $e');
    }
  }
}



import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/payment_api.dart';
import 'payment_api_provider.dart';

/// Provide a stream of CoinTransaction for a given userId
final coinTransactionStreamProvider =
    StreamProvider.family<List<CoinTransaction>, String>((ref, userId) {
      final paymentApi = ref.watch(paymentApiProvider);
      return PaymentApi.getTransactions(userId);
    });

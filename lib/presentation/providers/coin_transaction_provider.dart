import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coin_transaction_model.dart';

final coinTransactionListProvider = StateProvider<List<CoinTransactionModel>>(
  () => [],
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/coin_transaction_model.dart';

final coinTransactionListProvider = StateProvider<List<CoinTransactionModel>>((ref) => []);

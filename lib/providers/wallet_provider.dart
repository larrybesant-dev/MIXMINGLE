import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wallet_service.dart';
import '../models/user_wallet_model.dart';

final walletProvider = StreamProvider.family<UserWallet?, String>((ref, userId) {
  return WalletService().streamWallet(userId);
});

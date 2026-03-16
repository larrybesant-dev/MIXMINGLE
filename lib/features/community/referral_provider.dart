import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/referral_service.dart';

final referralServiceProvider = Provider<ReferralService>((ref) {
  return ReferralService();
});

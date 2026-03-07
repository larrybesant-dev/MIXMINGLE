import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/admin/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Real-time stream of all promo codes.
final promoCodesProvider = StreamProvider<List<PromoCode>>((ref) {
  return ref.watch(adminServiceProvider).promoCodesStream();
});

/// One-shot dashboard stats snapshot.
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.read(adminServiceProvider).getDashboardStats();
});

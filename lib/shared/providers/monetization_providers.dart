// lib/providers/monetization_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../models/entitlement_model.dart';

final monetizationServiceProvider = Provider<MonetizationService>((ref) => MonetizationService());
final userEntitlementProvider = Provider.family<EntitlementModel, String>((ref, userId) => ref.read(monetizationServiceProvider).getUserEntitlement(userId));

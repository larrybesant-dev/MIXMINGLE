import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/discovery_service.dart';

final discoveryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DiscoveryService().getDiscoveries();
});

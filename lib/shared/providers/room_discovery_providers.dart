// lib/providers/room_discovery_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/room_discovery_service.dart';

final roomDiscoveryServiceProvider =
    Provider<RoomDiscoveryService>((ref) => RoomDiscoveryService());

final trendingRoomsProvider =
    FutureProvider<List<DocumentSnapshot>>((ref) async {
  final service = ref.read(roomDiscoveryServiceProvider);
  return service.getTrendingRooms();
});

final activeRoomsProvider =
    FutureProvider<List<DocumentSnapshot>>((ref) async {
  final service = ref.read(roomDiscoveryServiceProvider);
  return service.getRoomsByCategory('active');
});

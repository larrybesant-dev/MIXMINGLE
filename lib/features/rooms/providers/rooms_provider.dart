/// Rooms Provider - Stub for compilation
/// TODO: Implement full rooms state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/room.dart';

/// Rooms state model
class RoomsState {
  final List<Room> rooms;
  final bool isLoading;
  final String? error;

  RoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });
}

/// Rooms provider - fetches all available rooms
final roomsProvider = Provider<RoomsState>((ref) {
  // TODO: Implement actual room fetching from Firestore
  return RoomsState();
});

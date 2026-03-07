/// Rooms Provider - State management for rooms list
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  RoomsState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    String? error,
  }) =>
      RoomsState(
        rooms: rooms ?? this.rooms,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Rooms notifier (Riverpod 3.x Notifier)
class RoomsNotifier extends Notifier<RoomsState> {
  final _firestore = FirebaseFirestore.instance;
  List<Room> _allRooms = [];

  @override
  RoomsState build() {
    _loadRooms();
    return RoomsState();
  }

  Future<void> _loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snap = await _firestore
          .collection('rooms')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      _allRooms = snap.docs
          .map((d) => Room.fromMap(d.data()..['id'] = d.id))
          .toList();
      state = state.copyWith(rooms: _allRooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(
      rooms: category == null
          ? _allRooms
          : _allRooms.where((r) => r.category == category).toList(),
    );
  }

  Future<String?> createRoom({
    required String name,
    String? description,
    String? category,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final doc = _firestore.collection('rooms').doc();
      final roomData = {
        'id': doc.id,
        'title': name,
        'description': description ?? '',
        'category': category ?? 'General',
        'hostId': uid,
        'ownerId': uid,
        'isLive': false,
        'participantIds': [uid],
        'viewerCount': 0,
        'activeBroadcasters': [],
        'isMusicPlaying': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await doc.set(roomData);
      // Reload rooms list
      await _loadRooms();
      return doc.id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

/// Rooms provider
final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(RoomsNotifier.new);



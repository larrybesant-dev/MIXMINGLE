import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_logger.dart';
import '../models/room_video_state_model.dart';
import '../models/video_tile_model.dart';
import '../models/window_state_model.dart';
import '../models/publisher_state_model.dart';

class RoomVideoStateController {
  final String roomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RoomVideoStateModel _currentState;
  StreamSubscription<DocumentSnapshot>? _subscription;

  RoomVideoStateController(this.roomId, RoomVideoStateModel initialState)
      : _currentState = initialState {
    _startListening();
  }

  RoomVideoStateModel get currentState => _currentState;

  void _startListening() {
    _subscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('videoState')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _currentState = RoomVideoStateModel.fromJson(data);
      }
    });
  }

  // Update the state in Firestore
  Future<void> updateState(RoomVideoStateModel newState) async {
    _currentState = newState;
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('videoState')
        .doc('current')
        .set(newState.toJson());
  }

  // Add a video tile
  Future<void> addVideoTile(VideoTileModel tile, WindowStateModel windowState) async {
    final newTiles = [..._currentState.videoTiles, tile];
    final newWindows = [..._currentState.windowStates, windowState];
    final newState = _currentState.copyWith(
      videoTiles: newTiles,
      windowStates: newWindows,
    );
    await updateState(newState);
  }

  // Remove a video tile
  Future<void> removeVideoTile(String tileId) async {
    final newTiles = _currentState.videoTiles.where((t) => t.id != tileId).toList();
    final newWindows = _currentState.windowStates.where((w) => w.videoTileId != tileId).toList();
    final newState = _currentState.copyWith(
      videoTiles: newTiles,
      windowStates: newWindows,
    );
    await updateState(newState);
  }

  // Update video tile
  Future<void> updateVideoTile(VideoTileModel updatedTile) async {
    final newTiles = _currentState.videoTiles.map((t) =>
      t.id == updatedTile.id ? updatedTile : t
    ).toList();
    final newState = _currentState.copyWith(videoTiles: newTiles);
    await updateState(newState);
  }

  // Update window state
  Future<void> updateWindowState(WindowStateModel updatedWindow) async {
    final newWindows = _currentState.windowStates.map((w) =>
      w.id == updatedWindow.id ? updatedWindow : w
    ).toList();
    final newState = _currentState.copyWith(windowStates: newWindows);
    await updateState(newState);
  }

  // Add publisher
  Future<void> addPublisher(PublisherStateModel publisher) async {
    final newPublishers = [..._currentState.publishers, publisher];
    final newState = _currentState.copyWith(publishers: newPublishers);
    await updateState(newState);
  }

  // Update publisher
  Future<void> updatePublisher(PublisherStateModel updatedPublisher) async {
    final newPublishers = _currentState.publishers.map((p) =>
      p.userId == updatedPublisher.userId ? updatedPublisher : p
    ).toList();
    final newState = _currentState.copyWith(publishers: newPublishers);
    await updateState(newState);
  }

  // Change layout
  Future<void> changeLayout(RoomVideoLayout newLayout) async {
    final newState = _currentState.copyWith(layout: newLayout);
    await updateState(newState);
  }

  // Enforce publisher limit
  Future<void> enforcePublisherLimit() async {
    final activeCount = _currentState.activePublishers;
    if (activeCount > _currentState.maxPublishers) {
      // Disable oldest publishers or something
      // For now, just log
      AppLogger.warning('Publisher limit exceeded: $activeCount > ${_currentState.maxPublishers}');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

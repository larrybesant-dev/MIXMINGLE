/// Agora Room Controller
///
/// High-level orchestration of:
/// - Join flow state machine (JoinFlowController)
/// - Agora SDK operations (AgoraService)
/// - Firestore presence sync (RoomFirestoreService)
/// - Participant list management
/// - Energy level calculation
///
/// Reference: DESIGN_BIBLE.md Section G (Complete Integration)
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import './join_flow_controller.dart';
import '../models/participant.dart';
import '../services/agora_service.dart';
import '../services/room_firestore_service.dart';

/// Exception thrown when room operations fail
class RoomControllerException implements Exception {
  final String message;
  final Object? originalError;

  RoomControllerException(this.message, [this.originalError]);

  @override
  String toString() => 'RoomControllerException: $message';
}

/// Main controller for video room
class AgoraRoomController extends ChangeNotifier {
  /// Services
  final AgoraService _agora;
  final RoomFirestoreService _firestore;
  final JoinFlowController _joinFlow;

  /// Room state (can be injected after creation)
  late String _roomId;
  late String _userId;
  late String _userName;

  /// Participants in room
  List<Participant> _participants = [];
  List<Participant> get participants => _participants;

  /// Room energy (0.0-10.0, from presence + speaking + activity)
  double _energy = 0.0;
  double get energy => _energy;

  /// Whether user is in the room
  bool _isInRoom = false;
  bool get isInRoom => _isInRoom;

  /// Microphone muted state
  bool _micMuted = false;
  bool get isMicMuted => _micMuted;

  /// Video muted state
  bool _videoMuted = false;
  bool get isVideoMuted => _videoMuted;

  /// Listeners management
  StreamSubscription? _participantsSubscription;

  AgoraRoomController({
    required AgoraService agora,
    required RoomFirestoreService firestore,
    required JoinFlowController joinFlow,
    String roomId = '',
    String userId = '',
    String userName = '',
  })  : _agora = agora,
        _firestore = firestore,
        _joinFlow = joinFlow,
        _roomId = roomId,
        _userId = userId,
        _userName = userName;

  /// Set room context (roomId, userId, userName)
  /// Must be called before joinRoom()
  void setRoomContext({
    required String roomId,
    required String userId,
    required String userName,
  }) {
    _roomId = roomId;
    _userId = userId;
    _userName = userName;

    // Clean up old listeners if any
    _participantsSubscription?.cancel();

    // Initialize listeners for this room
    _initializeListeners();
  }

  /// Initialize Firestore listeners for presence updates
  void _initializeListeners() {
    if (_roomId.isEmpty) {
      if (kDebugMode) print('[RoomController] Room context not set; skipping listeners');
      return;
    }

    _participantsSubscription = _firestore.participantsStream(_roomId).listen(
      (participants) {
        _participants = participants;
        _calculateEnergy();
        notifyListeners();

        if (kDebugMode) {
          print('[RoomController] Participants: ${participants.length}, Energy: ${_energy.toStringAsFixed(1)}');
        }
      },
      onError: (e) {
        if (kDebugMode) print('[RoomController] Participant stream error: $e');
      },
    );
  }

  /// Join room with ceremonial flow + Agora + Firestore sync
  ///
  /// Steps:
  /// 1. Start ceremonial join flow (150+400+400ms)
  /// 2. Initialize Agora SDK (if needed)
  /// 3. Join Agora channel with token
  /// 4. Add user to Firestore room presence
  /// 5. Return to UI
  Future<void> joinRoom({
    required String agoraToken,
  }) async {
    if (_isInRoom) return;

    try {
      // STEP 1: Start ceremonial join flow
      await _joinFlow.startJoinFlow();

      // STEP 2-3: Initialize & join Agora (happens during joining phase)
      if (!_agora.isInitialized) {
        await _agora.initialize();
      }
      await _agora.joinChannel(
        token: agoraToken,
        channelId: _roomId,
        uid: _userId,
      );

      // STEP 4: Add self to Firestore presence
      final selfParticipant = Participant(
        uid: _userId,
        name: _userName,
        isSpeaking: false,
        isPresent: true,
      );
      await _firestore.updateParticipant(_roomId, selfParticipant);

      // STEP 5: Update state
      _isInRoom = true;
      notifyListeners();

      if (kDebugMode) {
        print('[RoomController] Joined room: $_roomId as $_userName');
      }
    } catch (e) {
      _joinFlow.setError(e.toString());
      if (kDebugMode) print('[RoomController] Join failed: $e');
      throw RoomControllerException('Failed to join room', e);
    }
  }

  /// Leave room gracefully
  ///
  /// Steps:
  /// 1. Leave Agora channel
  /// 2. Remove from Firestore presence
  /// 3. Update local state
  Future<void> leaveRoom() async {
    if (!_isInRoom) return;

    try {
      // STEP 1: Leave Agora
      await _agora.leaveChannel();

      // STEP 2: Remove from Firestore
      await _firestore.removeParticipant(_roomId, _userId);

      // STEP 3: Update state
      _isInRoom = false;
      _joinFlow.reset();
      notifyListeners();

      if (kDebugMode) {
        print('[RoomController] Left room: $_roomId');
      }
    } catch (e) {
      if (kDebugMode) print('[RoomController] Leave failed: $e');
      // Don't throw; attempt cleanup even on error
    }
  }

  /// Toggle microphone
  Future<void> toggleMicrophone() async {
    try {
      _micMuted = !_micMuted;
      await _agora.setMicrophoneMuted(_micMuted);

      // Update Firestore if in room
      if (_isInRoom) {
        final self = _participants.firstWhere(
          (p) => p.uid == _userId,
          orElse: () => Participant(uid: _userId, name: _userName),
        );
        await _firestore.updateParticipant(
          _roomId,
          self.copyWith(),  // Just update presence timestamp
        );
      }

      notifyListeners();

      if (kDebugMode) {
        print('[RoomController] Mic: ${_micMuted ? 'MUTED' : 'ACTIVE'}');
      }
    } catch (e) {
      if (kDebugMode) print('[RoomController] Mic toggle failed: $e');
      _micMuted = !_micMuted; // Revert on error
      throw RoomControllerException('Failed to toggle microphone', e);
    }
  }

  /// Toggle camera video
  Future<void> toggleVideo() async {
    try {
      _videoMuted = !_videoMuted;
      await _agora.setVideoCameraMuted(_videoMuted);

      // Update Firestore if in room
      if (_isInRoom) {
        final self = _participants.firstWhere(
          (p) => p.uid == _userId,
          orElse: () => Participant(uid: _userId, name: _userName),
        );
        await _firestore.updateParticipant(
          _roomId,
          self.copyWith(),
        );
      }

      notifyListeners();

      if (kDebugMode) {
        print('[RoomController] Video: ${_videoMuted ? 'DISABLED' : 'ACTIVE'}');
      }
    } catch (e) {
      if (kDebugMode) print('[RoomController] Video toggle failed: $e');
      _videoMuted = !_videoMuted; // Revert on error
      throw RoomControllerException('Failed to toggle video', e);
    }
  }

  /// Update speaking state
  /// Called when Agora detects user is speaking
  Future<void> setSpeaking(bool speaking) async {
    try {
      final self = _participants.firstWhere(
        (p) => p.uid == _userId,
        orElse: () => Participant(uid: _userId, name: _userName, isSpeaking: speaking),
      );

      if (self.isSpeaking != speaking) {
        final updated = self.copyWith(isSpeaking: speaking);
        await _firestore.updateParticipant(_roomId, updated);
      }
    } catch (e) {
      if (kDebugMode) print('[RoomController] Set speaking failed: $e');
      // Don't throw; speaking state is secondary
    }
  }

  /// Calculate room energy from presence + speaking + activity
  ///
  /// Formula:
  /// energy = (speaking_count / total_count) * 5 + (total_count * 0.5)
  /// Ranges: 0.0 (empty) to 10.0 (full room, all speaking)
  void _calculateEnergy() {
    if (_participants.isEmpty) {
      _energy = 0.0;
      return;
    }

    final speakingCount = _participants.where((p) => p.isSpeaking).length;
    final totalCount = _participants.length;

    // Speaking contribution + presence contribution
    _energy = (speakingCount / totalCount) * 5.0 + (totalCount * 0.5);

    // Constrain to 0-10
    _energy = _energy.clamp(0.0, 10.0);
  }

  /// Get human-readable energy label
  String getEnergyLabel() {
    if (_energy < 2) return 'Calm';
    if (_energy < 5) return 'Active';
    return 'Buzzing';
  }

  /// Cleanup on disposal
  @override
  void dispose() {
    _participantsSubscription?.cancel();
    _leaveRoomSilent();
    super.dispose();
  }

  /// Leave room without throwing exceptions
  Future<void> _leaveRoomSilent() async {
    try {
      await leaveRoom();
    } catch (e) {
      if (kDebugMode) print('[RoomController] Cleanup error: $e');
    }
  }
}

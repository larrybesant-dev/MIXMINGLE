import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mixmingle/shared/models/room.dart';

class RoomService {
    // Advanced role management
    Future<void> promoteToCoHost(String roomId, String userId) async {
      await _assertAdminOrOwner(roomId, _currentUserId);
      await _firestore.collection('rooms').doc(roomId).update({
        'moderators': FieldValue.arrayUnion([userId]),
        'roleMap.$userId': 'coHost',
      });
    }

    Future<void> demoteFromCoHost(String roomId, String userId) async {
      await _firestore.collection('rooms').doc(roomId).update({
        'moderators': FieldValue.arrayRemove([userId]),
        'roleMap.$userId': 'guest',
      });
    }

    Future<void> transferHostRole(String roomId, String newHostId) async {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (!doc.exists) throw Exception('Room not found');
      final d = doc.data()!;
      final ownerId = d['ownerId'] as String? ?? d['hostId'] as String? ?? '';
      if (_currentUserId != ownerId) throw Exception('Only the owner can transfer host role');
      await _firestore.collection('rooms').doc(roomId).update({
        'hostId': newHostId,
        'roleMap.$newHostId': 'host',
      });
    }

    // Spotlight stage layout
    Future<void> setSpotlighted(String roomId, String userId, bool isSpotlighted) async {
      await _firestore.collection('rooms').doc(roomId).update({
        'spotlighted': isSpotlighted ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
        'participantMap.$userId.isSpotlighted': isSpotlighted,
      });
    }

    // Breakout room hooks (future-ready)
    Future<void> createBreakoutRoom(String parentRoomId, String name, List<String> participantUids) async {
      // Skeleton only: store under parent room
      await _firestore.collection('rooms').doc(parentRoomId).collection('breakoutRooms').add({
        'name': name,
        'participantUids': participantUids,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // Reliability: Retry flows for join/leave, token, permissions
    Future<T> retry<T>(Future<T> Function() action, {int maxAttempts = 3, Duration delay = const Duration(seconds: 2)}) async {
      int attempts = 0;
      while (true) {
        try {
          return await action();
        } catch (e) {
          attempts++;
          if (attempts >= maxAttempts) rethrow;
          await Future.delayed(delay);
        }
      }
    }

    // Graceful teardown on navigation away
    Future<void> teardownRoom(String roomId, String userId) async {
      try {
        await leaveVoiceRoom(roomId, userId);
        // Additional teardown logic (Agora, providers, etc.)
      } catch (e) {
        debugPrint('Teardown error: $e');
      }
    }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new voice room
  Future<Room> createVoiceRoom({
    required String hostId,
    required String hostName,
    required String title,
    required String description,
    required List<String> tags,
    required String category,
    String privacy = 'public',
  }) async {
    // Rate limit check
    await _checkRateLimitServer(
      uid: hostId,
      action: 'create_room',
      limit: 10,
      windowSeconds: 3600, // 10 rooms per hour
    );

    final roomId = _firestore.collection('rooms').doc().id;
    final agoraChannelName = 'room_$roomId';

    final room = Room(
      id: roomId,
      name: title,
      hostId: hostId,
      ownerId: hostId,
      participantIds: [hostId], // Host is automatically a participant
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      title: title,
      description: description,
      tags: tags,
      privacy: privacy,
      status: 'live',
      category: category,
      hostName: hostName,
      viewerCount: 1,
      isLive: true,
      roomType: RoomType.voice,
      moderators: [hostId], // Host is automatically a moderator
      bannedUsers: [],
      agoraChannelName: agoraChannelName,
      speakers: [hostId], // Host starts as speaker
      listeners: [],
      admins: [hostId],
    );

    // Add creatorId for Firestore security rules
    final roomData = room.toMap();
    roomData['creatorId'] = hostId;
    roomData['ownerId'] = hostId;
    if (!(roomData['admins'] as List).contains(hostId)) {
      (roomData['admins'] as List).add(hostId);
    }
    roomData['createdAt'] = FieldValue.serverTimestamp();
    // Ensure LiveRoom schema fields are initialized on creation
    roomData['videoChannelLive']  = false;  // set to true by controller when first user enters
    roomData['participantCount']  = 0;
    roomData['maxBroadcasters']   ??= 4;
    roomData['maxActiveMics']     ??= 4;
    // URL-safe slug: lowercase title, non-alphanumeric → hyphens, trim leading/trailing hyphens, + 8-char roomId suffix
    roomData['slug'] = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '')}-${roomId.substring(0, 8)}';

    await _firestore.collection('rooms').doc(roomId).set(roomData);
    return room;
  }

  // Join a voice room - Phase 3: Transaction-based for atomicity
  Future<void> joinVoiceRoom(String roomId, String userId, String userName) async {
    // Rate limit check
    await _checkRateLimitServer(
      uid: userId,
      action: 'join_room',
      limit: 100,
      windowSeconds: 3600, // 100 joins per hour
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final roomData = roomDoc.data()!;
        final bannedUsers = List<String>.from(roomData['bannedUsers'] ?? []);
        final ownerId = roomData['ownerId'] as String? ?? roomData['hostId'] as String? ?? '';
        final admins = List<String>.from(roomData['admins'] ?? []);
        final isPrivileged = userId == ownerId || admins.contains(userId);

        // Check if user is banned (privileged users bypass)
        if (!isPrivileged && bannedUsers.contains(userId)) {
          throw Exception('You are banned from this room');
        }

        // Check if room is locked (privileged users bypass)
        final isLocked = (roomData['isLocked'] as bool? ?? false) ||
            (roomData['isRoomLocked'] as bool? ?? false);
        if (!isPrivileged && isLocked) {
          throw Exception('This room is locked. Only admins can join.');
        }

        // Add user to participants
        final updatedParticipants = List<String>.from(roomData['participantIds'] ?? []);
        if (!updatedParticipants.contains(userId)) {
          // Capacity check: enforce maxUsers limit for non-privileged users
          final maxUsers = (roomData['maxUsers'] as int?) ?? 200;
          if (!isPrivileged && updatedParticipants.length >= maxUsers) {
            throw Exception('Room is at capacity ($maxUsers). Try again later.');
          }
          updatedParticipants.add(userId);
        }

        // Add user as listener by default
        final updatedListeners = List<String>.from(roomData['listeners'] ?? []);
        if (!updatedListeners.contains(userId)) {
          updatedListeners.add(userId);
        }

        transaction.update(roomRef, {
          'participantIds': updatedParticipants,
          'listeners': updatedListeners,
          'viewerCount': updatedParticipants.length,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('âŒ Failed to join room: $e');
      rethrow;
    }
  }

  // Leave a voice room - Phase 3: Transaction-based for atomicity
  Future<void> leaveVoiceRoom(String roomId, String userId) async {
    try {
      bool shouldEndRoom = false;
      String? hostId;

      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          return; // Room might have been deleted
        }

        final roomData = roomDoc.data()!;
        hostId = roomData['hostId'] as String?;
        final admins = List<String>.from(roomData['admins'] ?? []);

        // Remove user from all role lists
        final updatedParticipants = List<String>.from(roomData['participantIds'] ?? [])..remove(userId);
        final updatedSpeakers    = List<String>.from(roomData['speakers'] ?? [])..remove(userId);
        final updatedListeners   = List<String>.from(roomData['listeners'] ?? [])..remove(userId);
        // Admins retain their moderator slot so re-join is seamless
        final updatedModerators  = admins.contains(userId)
            ? List<String>.from(roomData['moderators'] ?? [])
            : List<String>.from(roomData['moderators'] ?? [])..remove(userId);

        transaction.update(roomRef, {
          'participantIds': updatedParticipants,
          'speakers': updatedSpeakers,
          'listeners': updatedListeners,
          'moderators': updatedModerators,
          'viewerCount': updatedParticipants.length,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        // Only auto-end if host left AND no other admin or moderator remains
        final hasRemainingPrivileged = updatedModerators.any((id) => id != userId) ||
            admins.any((id) => id != userId);
        if (hostId == userId && !hasRemainingPrivileged) {
          shouldEndRoom = true;
        }
      });

      // End room outside transaction if needed
      if (shouldEndRoom) {
        await endVoiceRoom(roomId);
      }
    } catch (e) {
      debugPrint('âŒ Failed to leave room: $e');
      rethrow;
    }
  }

  // Request to speak (listener -> speaker)
  Future<void> requestToSpeak(String roomId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if user is a listener
        if (!room.listeners.contains(userId)) {
          throw Exception('You must be a listener to request to speak');
        }

        // Add to speakers list
        final updatedSpeakers = List<String>.from(room.speakers);
        if (!updatedSpeakers.contains(userId)) {
          updatedSpeakers.add(userId);
        }

        // Remove from listeners
        final updatedListeners = List<String>.from(room.listeners)..remove(userId);

        transaction.update(roomRef, {
          'speakers': updatedSpeakers,
          'listeners': updatedListeners,
        });
      });
    } catch (e) {
      debugPrint('âŒ Failed to request to speak: $e');
      throw Exception('Failed to request to speak: $e');
    }
  }

  // Stop speaking (speaker -> listener)
  Future<void> stopSpeaking(String roomId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if user is a speaker
        if (!room.speakers.contains(userId)) {
          throw Exception('You are not currently speaking');
        }

        // Move to listeners
        final updatedSpeakers = List<String>.from(room.speakers)..remove(userId);
        final updatedListeners = List<String>.from(room.listeners);
        if (!updatedListeners.contains(userId)) {
          updatedListeners.add(userId);
        }

        transaction.update(roomRef, {
          'speakers': updatedSpeakers,
          'listeners': updatedListeners,
        });
      });
    } catch (e) {
      debugPrint('âŒ Failed to stop speaking: $e');
      throw Exception('Failed to stop speaking: $e');
    }
  }

  // Moderator actions
  Future<void> makeModerator(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is owner, admin, or moderator
        final isPrivilegedMod = moderatorId == room.ownerId ||
            room.admins.contains(moderatorId) ||
            room.moderators.contains(moderatorId);
        if (!isPrivilegedMod) {
          throw Exception('You are not authorized to perform this action');
        }

        final updatedModerators = List<String>.from(room.moderators);
        if (!updatedModerators.contains(targetUserId)) {
          updatedModerators.add(targetUserId);
        }

        transaction.update(roomRef, {'moderators': updatedModerators});
      });
    } catch (e) {
      debugPrint('âŒ Failed to make moderator: $e');
      throw Exception('Failed to make moderator: $e');
    }
  }

  Future<void> removeModerator(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Only owner can remove moderators
        if (moderatorId != room.ownerId && moderatorId != room.hostId) {
          throw Exception('Only the room owner can remove moderators');
        }

        if (targetUserId == room.ownerId || targetUserId == room.hostId) {
          throw Exception('Cannot remove the room owner as moderator');
        }

        final updatedModerators = List<String>.from(room.moderators)..remove(targetUserId);

        transaction.update(roomRef, {
          'moderators': updatedModerators,
        });
      });
    } catch (e) {
      debugPrint('âŒ Failed to remove moderator: $e');
      throw Exception('Failed to remove moderator: $e');
    }
  }

  Future<void> kickUser(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is owner, admin, or moderator
        final isPrivileged = moderatorId == room.ownerId ||
            room.admins.contains(moderatorId) ||
            room.moderators.contains(moderatorId);
        if (!isPrivileged) {
          throw Exception('You are not authorized to perform this action');
        }

        if (targetUserId == room.ownerId || targetUserId == room.hostId) {
          throw Exception('Cannot kick the room host');
        }

        // Remove user from all lists
        final updatedParticipants = List<String>.from(room.participantIds)..remove(targetUserId);
        final updatedSpeakers = List<String>.from(room.speakers)..remove(targetUserId);
        final updatedListeners = List<String>.from(room.listeners)..remove(targetUserId);
        final updatedModerators = List<String>.from(room.moderators)..remove(targetUserId);

        transaction.update(roomRef, {
          'participantIds': updatedParticipants,
          'speakers': updatedSpeakers,
          'listeners': updatedListeners,
          'moderators': updatedModerators,
          'viewerCount': updatedParticipants.length,
        });
      });
    } catch (e) {
      debugPrint('âŒ Failed to kick user: $e');
      throw Exception('Failed to kick user: $e');
    }
  }

  Future<void> banUser(String roomId, String moderatorId, String targetUserId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    // Single transaction: auth check + kick + ban array — no race window between kick and ban
    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) throw Exception('Room not found');

      final room = Room.fromDocument(roomDoc);

      final isPrivileged = moderatorId == room.ownerId ||
          room.admins.contains(moderatorId) ||
          room.moderators.contains(moderatorId);
      if (!isPrivileged) throw Exception('You are not authorized to perform this action');
      if (targetUserId == room.ownerId || targetUserId == room.hostId) {
        throw Exception('Cannot ban the room host');
      }

      final updatedParticipants = List<String>.from(room.participantIds)..remove(targetUserId);
      final updatedSpeakers    = List<String>.from(room.speakers)..remove(targetUserId);
      final updatedListeners   = List<String>.from(room.listeners)..remove(targetUserId);
      final updatedModerators  = List<String>.from(room.moderators)..remove(targetUserId);
      final updatedBanned      = List<String>.from(room.bannedUsers);
      if (!updatedBanned.contains(targetUserId)) updatedBanned.add(targetUserId);

      transaction.update(roomRef, {
        'participantIds': updatedParticipants,
        'speakers': updatedSpeakers,
        'listeners': updatedListeners,
        'moderators': updatedModerators,
        'viewerCount': updatedParticipants.length,
        'bannedUsers': updatedBanned,
      });
    });

    // Remove participant subcollection doc outside transaction to stay within 20-op limit
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(targetUserId)
        .delete()
        .catchError((_) {});
  }

  // ============================================================================
  // MODERATION ACTIONS - Phase 3.1e
  // ============================================================================

  /// Mute user (soft mute - can unmute themselves)
  Future<void> muteUser(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is a moderator
        if (!room.moderators.contains(moderatorId)) {
          throw Exception('You are not authorized to perform this action');
        }

        if (targetUserId == room.hostId) {
          throw Exception('Cannot mute the room host');
        }

        // Update participant's mic state in subcollection
        final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(targetUserId);

        transaction.update(participantRef, {
          'isMuted': true,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint('ðŸ”‡ User muted: $targetUserId');
    } catch (e) {
      debugPrint('âŒ Failed to mute user: $e');
      throw Exception('Failed to mute user: $e');
    }
  }

  /// Unmute user
  Future<void> unmuteUser(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is a moderator
        if (!room.moderators.contains(moderatorId)) {
          throw Exception('You are not authorized to perform this action');
        }

        // Update participant's mic state in subcollection
        final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(targetUserId);

        transaction.update(participantRef, {
          'isMuted': false,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint('ðŸ”Š User unmuted: $targetUserId');
    } catch (e) {
      debugPrint('âŒ Failed to unmute user: $e');
      throw Exception('Failed to unmute user: $e');
    }
  }

  /// Spotlight user (make them featured speaker)
  Future<void> spotlightUser(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is a moderator
        if (!room.moderators.contains(moderatorId)) {
          throw Exception('You are not authorized to perform this action');
        }

        // Set as current speaker
        transaction.update(roomRef, {
          'currentSpeakerId': targetUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Ensure user is in speakers list
        final updatedSpeakers = List<String>.from(room.speakers);
        final updatedListeners = List<String>.from(room.listeners);

        if (!updatedSpeakers.contains(targetUserId)) {
          updatedSpeakers.add(targetUserId);
          updatedListeners.remove(targetUserId);

          transaction.update(roomRef, {
            'speakers': updatedSpeakers,
            'listeners': updatedListeners,
          });
        }
      });
      debugPrint('â­ User spotlighted: $targetUserId');
    } catch (e) {
      debugPrint('âŒ Failed to spotlight user: $e');
      throw Exception('Failed to spotlight user: $e');
    }
  }

  /// Remove spotlight (clear current speaker)
  Future<void> removeSpotlight(String roomId, String moderatorId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is a moderator
        if (!room.moderators.contains(moderatorId)) {
          throw Exception('You are not authorized to perform this action');
        }

        transaction.update(roomRef, {
          'currentSpeakerId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint('â­ Spotlight removed');
    } catch (e) {
      debugPrint('âŒ Failed to remove spotlight: $e');
      throw Exception('Failed to remove spotlight: $e');
    }
  }

  // End voice room
  Future<void> endVoiceRoom(String roomId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    await roomRef.update({
      'status': 'ended',
      'isActive': false,
      'isLive': false,
      'viewerCount': 0,
      'participantCount': 0,
    });
  }

  // Get active voice rooms
  Stream<List<Room>> getActiveVoiceRooms() {
    return _firestore
        .collection('rooms')
        .where('roomType', isEqualTo: 'voice')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'live')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Room.fromDocument(doc)).toList();
    });
  }

  // Get room by ID
  Stream<Room?> getRoom(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
      if (doc.exists) {
        return Room.fromDocument(doc);
      }
      return null;
    });
  }

  // Get user's rooms
  Stream<List<Room>> getUserRooms(String userId) {
    return _firestore
        .collection('rooms')
        .where('participantIds', arrayContains: userId)
        .where('roomType', isEqualTo: 'voice')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Room.fromDocument(doc)).toList();
    });
  }

  // Generic room search by title (prefix)
  Future<List<QueryDocumentSnapshot>> searchRooms(String q, {int limit = 30}) async {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return [];
    final snap = await _firestore
        .collection('rooms')
        .where('title_lower', isGreaterThanOrEqualTo: s)
        .where('title_lower', isLessThanOrEqualTo: '$s\uf8ff')
        .limit(limit)
        .get();
    return snap.docs;
  }

  // Filter example: rooms by tag or participant
  Future<List<QueryDocumentSnapshot>> filterRooms({String? tag, String? participantUid, int limit = 30}) async {
    Query q = _firestore.collection('rooms');
    if (tag != null) q = q.where('tags', arrayContains: tag);
    if (participantUid != null) {
      q = q.where('participants', arrayContains: participantUid);
    }
    final snap = await q.limit(limit).get();
    return snap.docs;
  }

  // Update room title
  Future<void> updateRoomTitle(String roomId, String newTitle) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'title': newTitle,
      'name': newTitle, // Assuming name is also the title
    });
  }

  // Update room description
  Future<void> updateRoomDescription(String roomId, String newDescription) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'description': newDescription,
    });
  }

  // Update allow speaker requests
  Future<void> updateAllowSpeakerRequests(String roomId, bool allow) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'allowSpeakerRequests': allow,
    });
  }

  // Update turn-based speaking flag
  Future<void> updateTurnBased(String roomId, bool turnBased) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'turnBased': turnBased,
    });
  }

  // ============ PROVIDER-EXPECTED METHODS ============

  /// Delete a room
  Future<void> deleteRoom(String roomId, String userId) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);
    if (room.hostId != userId) {
      throw Exception('Only host can delete room');
    }

    await _firestore.collection('rooms').doc(roomId).delete();
  }

  /// Invite user to room
  Future<void> inviteUser(String roomId, String userId, String invitedUserId) async {
    // Store invitation
    await _firestore.collection('roomInvitations').add({
      'roomId': roomId,
      'inviterId': userId,
      'invitedUserId': invitedUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Remove participant from room
  Future<void> removeParticipant(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);
    final updatedParticipants = List<String>.from(room.participantIds)..remove(userId);
    final updatedSpeakers = List<String>.from(room.speakers)..remove(userId);
    final updatedListeners = List<String>.from(room.listeners)..remove(userId);

    await roomRef.update({
      'participantIds': updatedParticipants,
      'speakers': updatedSpeakers,
      'listeners': updatedListeners,
      'viewerCount': FieldValue.increment(-1),
    });
  }

  /// Promote listener to speaker
  Future<void> promoteToSpeaker(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);
    final updatedSpeakers = List<String>.from(room.speakers);
    final updatedListeners = List<String>.from(room.listeners);

    if (!updatedSpeakers.contains(userId) && updatedListeners.contains(userId)) {
      updatedSpeakers.add(userId);
      updatedListeners.remove(userId);

      await roomRef.update({
        'speakers': updatedSpeakers,
        'listeners': updatedListeners,
      });
    }
  }

  /// Demote speaker to listener
  Future<void> demoteToListener(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);
    final updatedSpeakers = List<String>.from(room.speakers);
    final updatedListeners = List<String>.from(room.listeners);

    if (updatedSpeakers.contains(userId) && !updatedListeners.contains(userId)) {
      updatedSpeakers.remove(userId);
      updatedListeners.add(userId);

      await roomRef.update({
        'speakers': updatedSpeakers,
        'listeners': updatedListeners,
      });
    }
  }

  // ============================================================================
  // TURN-BASED MODE ENFORCEMENT
  // ============================================================================

  /// Grant speaking turn to a user (turn-based mode)
  /// Only moderators can grant turns
  Future<void> grantTurn(String roomId, String moderatorId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);

    // Check if requester is a moderator
    if (!room.moderators.contains(moderatorId)) {
      throw Exception('You are not authorized to grant turns');
    }

    // Check if room is in turn-based mode
    if (!room.turnBased) {
      throw Exception('Turn-based mode is not enabled');
    }

    // Check if user is a participant
    if (!room.participantIds.contains(userId)) {
      throw Exception('User is not in the room');
    }

    // Update current speaker and move user to speakers list
    final updatedListeners = List<String>.from(room.listeners);
    final updatedSpeakers = List<String>.from(room.speakers);

    if (updatedListeners.contains(userId)) {
      updatedListeners.remove(userId);
      if (!updatedSpeakers.contains(userId)) {
        updatedSpeakers.add(userId);
      }
    }

    await roomRef.update({
      'currentSpeakerId': userId,
      'speakers': updatedSpeakers,
      'listeners': updatedListeners,
    });

    debugPrint('ðŸŽ¤ Turn granted to: $userId');
  }

  /// End the current speaker's turn (turn-based mode)
  /// Can be called by moderators or the current speaker
  Future<void> endTurn(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);

    // Check if requester is moderator or the current speaker
    final isCurrentSpeaker = room.currentSpeakerId == userId;
    final isModerator = room.moderators.contains(userId);

    if (!isCurrentSpeaker && !isModerator) {
      throw Exception('You are not authorized to end this turn');
    }

    // Check if room is in turn-based mode
    if (!room.turnBased) {
      throw Exception('Turn-based mode is not enabled');
    }

    // Clear current speaker but keep user in speakers list
    await roomRef.update({
      'currentSpeakerId': FieldValue.delete(),
    });

    debugPrint('â¹ï¸ Turn ended for: ${room.currentSpeakerId}');
  }

  // ============================================================================
  // RAISE HAND & SPEAKER QUEUE MANAGEMENT
  // ============================================================================

  /// User raises hand to request speaking turn
  Future<void> raiseHand(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);

    // Check if user is a participant
    if (!room.participantIds.contains(userId)) {
      throw Exception('You are not in the room');
    }

    // Check if already raised hand
    if (room.raisedHands.contains(userId)) {
      throw Exception('Hand already raised');
    }

    // Add to raised hands and speaker queue
    final updatedRaisedHands = List<String>.from(room.raisedHands)..add(userId);
    final updatedQueue = List<String>.from(room.speakerQueue);

    if (!updatedQueue.contains(userId)) {
      updatedQueue.add(userId);
    }

    await roomRef.update({
      'raisedHands': updatedRaisedHands,
      'speakerQueue': updatedQueue,
    });

    debugPrint('ðŸ–ï¸ Hand raised by: $userId');
  }

  /// User lowers hand (withdraws request)
  Future<void> lowerHand(String roomId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);

    // Remove from raised hands and speaker queue
    final updatedRaisedHands = List<String>.from(room.raisedHands)..remove(userId);
    final updatedQueue = List<String>.from(room.speakerQueue)..remove(userId);

    await roomRef.update({
      'raisedHands': updatedRaisedHands,
      'speakerQueue': updatedQueue,
    });

    debugPrint('ðŸ‘‡ Hand lowered by: $userId');
  }

  /// Approve raised hand - promote listener to speaker (Phase 3.1c)
  Future<void> approveRaisedHand(String roomId, String moderatorId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('Room not found');
        }

        final room = Room.fromDocument(roomDoc);

        // Check if requester is a moderator
        if (!room.moderators.contains(moderatorId)) {
          throw Exception('You are not authorized to perform this action');
        }

        // Remove from raisedHands, speakerQueue, and listeners; add to speakers
        final updatedRaisedHands = List<String>.from(room.raisedHands)..remove(targetUserId);
        final updatedQueue = List<String>.from(room.speakerQueue)..remove(targetUserId);
        final updatedListeners = List<String>.from(room.listeners)..remove(targetUserId);
        final updatedSpeakers = List<String>.from(room.speakers);
        if (!updatedSpeakers.contains(targetUserId)) {
          updatedSpeakers.add(targetUserId);
        }

        transaction.update(roomRef, {
          'raisedHands': updatedRaisedHands,
          'speakerQueue': updatedQueue,
          'listeners': updatedListeners,
          'speakers': updatedSpeakers,
        });
      });
      debugPrint('âœ… Approved raised hand: $targetUserId â†’ now speaker');
    } catch (e) {
      debugPrint('âŒ Failed to approve raised hand: $e');
      throw Exception('Failed to approve raised hand: $e');
    }
  }

  /// Grant turn to next person in queue
  Future<void> grantTurnFromQueue(String roomId, String moderatorId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final room = Room.fromDocument(roomDoc);

    // Check if requester is a moderator
    if (!room.moderators.contains(moderatorId)) {
      throw Exception('You are not authorized to grant turns');
    }

    // Check if room is in turn-based mode
    if (!room.turnBased) {
      throw Exception('Turn-based mode is not enabled');
    }

    // Get next person from queue
    if (room.speakerQueue.isEmpty) {
      throw Exception('No one in speaker queue');
    }

    final nextSpeakerId = room.speakerQueue.first;
    final updatedQueue = List<String>.from(room.speakerQueue)..removeAt(0);
    final updatedRaisedHands = List<String>.from(room.raisedHands)..remove(nextSpeakerId);

    // Move to speakers list if not already there
    final updatedListeners = List<String>.from(room.listeners);
    final updatedSpeakers = List<String>.from(room.speakers);

    if (updatedListeners.contains(nextSpeakerId)) {
      updatedListeners.remove(nextSpeakerId);
      if (!updatedSpeakers.contains(nextSpeakerId)) {
        updatedSpeakers.add(nextSpeakerId);
      }
    }

    await roomRef.update({
      'currentSpeakerId': nextSpeakerId,
      'speakerQueue': updatedQueue,
      'raisedHands': updatedRaisedHands,
      'speakers': updatedSpeakers,
      'listeners': updatedListeners,
    });

    debugPrint('ðŸŽ¤ Turn granted to: $nextSpeakerId from queue');
  }

  /// Get speaker queue (for UI display)
  List<String> getSpeakerQueue(String roomId) {
    // Note: This would normally fetch from Firestore
    // For now, it's read-only from the Room object
    return [];
  }

  // ============================================================================
  // AGORA STATE SYNCHRONIZATION - Phase 3.1d
  // ============================================================================

  /// Update participant mic state in Firestore
  Future<void> updateMicState(String roomId, String userId, bool isMuted) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'isMuted': isMuted,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ðŸŽ¤ Mic state updated: $userId â†’ ${isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      debugPrint('âŒ Failed to update mic state: $e');
      // Retry once
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);
        await participantRef.update({
          'isMuted': isMuted,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      } catch (retryError) {
        debugPrint('âŒ Retry failed for mic state: $retryError');
      }
    }
  }

  /// Update participant camera state in Firestore
  Future<void> updateCameraState(String roomId, String userId, bool isOff) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'isOnCam': !isOff,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ðŸŽ¥ Camera state updated: $userId â†’ ${isOff ? "off" : "on"}');
    } catch (e) {
      debugPrint('âŒ Failed to update camera state: $e');
      // Retry once
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);
        await participantRef.update({
          'isOnCam': !isOff,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      } catch (retryError) {
        debugPrint('âŒ Retry failed for camera state: $retryError');
      }
    }
  }

  /// Update participant speaking state in Firestore
  Future<void> updateSpeakingState(String roomId, String userId, bool isSpeaking) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'isSpeaking': isSpeaking,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Only log when speaking starts (not every volume indication)
      if (isSpeaking) {
        debugPrint('ðŸ”Š Speaking state: $userId is speaking');
      }
    } catch (e) {
      // Silent fail for speaking state (happens frequently)
      debugPrint('âš ï¸ Failed to update speaking state: $e');
    }
  }

  /// Update participant network quality in Firestore
  Future<void> updateNetworkQuality(String roomId, String userId, String quality) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'connectionQuality': quality,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      if (quality == 'poor' || quality == 'unknown') {
        debugPrint('ðŸ“¶ Network quality: $userId â†’ $quality');
      }
    } catch (e) {
      // Silent fail for network quality updates
      debugPrint('âš ï¸ Failed to update network quality: $e');
    }
  }

  /// Update participant connection state in Firestore
  Future<void> updateConnectionState(String roomId, String userId, String state) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'connectionState': state,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ðŸ”„ Connection state: $userId â†’ $state');
    } catch (e) {
      debugPrint('âš ï¸ Failed to update connection state: $e');
    }
  }

  /// Mark user as online in Firestore
  Future<void> markUserOnline(String roomId, String userId) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'isOnline': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('âœ… User online: $userId');
    } catch (e) {
      debugPrint('âš ï¸ Failed to mark user online: $e');
    }
  }

  /// Mark user as offline in Firestore
  Future<void> markUserOffline(String roomId, String userId) async {
    try {
      final participantRef = _firestore.collection('rooms').doc(roomId).collection('participants').doc(userId);

      await participantRef.update({
        'isOnline': false,
        'isSpeaking': false,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('âŒ User offline: $userId');
    } catch (e) {
      debugPrint('âš ï¸ Failed to mark user offline: $e');
    }
  }

  // ============================================================================
  // RATE LIMIT CHECK
  // ============================================================================
  Future<void> _checkRateLimitServer({
    required String uid,
    required String action,
    required int limit,
    required int windowSeconds,
  }) async {
    try {
      final callable = _functions.httpsCallable('checkRateLimit');
      final result = await callable.call({
        'action': action,
        'limit': limit,
        'windowSeconds': windowSeconds,
      });
      final data = result.data as Map;
      final allowed = data['allowed'] == true;
      if (!allowed) {
        final retryAfterSeconds = (data['retryAfterSeconds'] as num?)?.toInt() ?? 0;
        throw Exception('Rate limit exceeded. Try again in ${retryAfterSeconds}s');
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        final retryAfterSeconds = (e.details?['retryAfterSeconds'] as num?)?.toInt() ?? 0;
        throw Exception('Rate limit exceeded. Try again in ${retryAfterSeconds}s');
      }
      throw Exception('Rate limit check failed: ${e.message}');
    } catch (e) {
      debugPrint('Rate limit function unavailable: $e');
      // Proceed if function unavailable to avoid hard dependency
    }
  }

  // ============================================================================
  // ADMIN ACTIONS — owner / admin only
  // ============================================================================

  Future<void> _assertAdminOrOwner(String roomId, String callerId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) throw Exception('Room not found');
    final data = doc.data()!;
    final ownerId = data['ownerId'] as String? ?? data['hostId'] as String? ?? '';
    final admins = List<String>.from(data['admins'] ?? []);
    if (callerId != ownerId && !admins.contains(callerId)) {
      throw Exception('Unauthorized: you are not an owner or admin of this room');
    }
  }

  Future<void> adminKickUser(String roomId, String targetUserId) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);

    final roomRef = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(roomRef);
      if (!snap.exists) throw Exception('Room not found');
      final data = snap.data()!;
      final ownerId = data['ownerId'] as String? ?? data['hostId'] as String? ?? '';
      if (targetUserId == ownerId) throw Exception('Cannot kick the room owner');

      final participants = List<String>.from(data['participantIds'] ?? [])..remove(targetUserId);
      final speakers = List<String>.from(data['speakers'] ?? [])..remove(targetUserId);
      final listeners = List<String>.from(data['listeners'] ?? [])..remove(targetUserId);
      final mods = List<String>.from(data['moderators'] ?? [])..remove(targetUserId);
      tx.update(roomRef, {
        'participantIds': participants,
        'speakers': speakers,
        'listeners': listeners,
        'moderators': mods,
        'viewerCount': participants.length,
        'kickedUsers': FieldValue.arrayUnion([targetUserId]),
      });
    });

    await _firestore.collection('rooms').doc(roomId).collection('participants').doc(targetUserId).delete();
  }

  Future<void> unbanUser(String roomId, String targetUserId) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);

    await _firestore.collection('rooms').doc(roomId).update({
      'bannedUsers': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove from both canonical 'bans' subcollection and legacy 'banned_users' subcollection
    final roomRef = _firestore.collection('rooms').doc(roomId);
    await Future.wait([
      roomRef.collection('bans').doc(targetUserId).delete().catchError((_) {}),
      roomRef.collection('banned_users').doc(targetUserId).delete().catchError((_) {}),
    ]);
  }

  Future<void> adminBanUser(String roomId, String targetUserId) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);

    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) throw Exception('Room not found');
    final data = doc.data()!;
    final ownerId = data['ownerId'] as String? ?? data['hostId'] as String? ?? '';
    if (targetUserId == ownerId) throw Exception('Cannot ban the room owner');

    await adminKickUser(roomId, targetUserId);

    await _firestore.collection('rooms').doc(roomId).update({
      'bannedUsers': FieldValue.arrayUnion([targetUserId]),
    });

    await _firestore.collection('rooms').doc(roomId).collection('bans').doc(targetUserId).set({
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': currentUserId,
    });
  }

  Future<void> makeAdmin(String roomId, String targetUserId) async {
    final currentUserId = _currentUserId;
    // Only the owner may add admins — admins cannot self-escalate or promote others
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) throw Exception('Room not found');
    final data = doc.data()!;
    final ownerId = data['ownerId'] as String? ?? data['hostId'] as String? ?? '';
    if (currentUserId != ownerId) throw Exception('Only the owner can add admins');

    await _firestore.collection('rooms').doc(roomId).update({
      'admins': FieldValue.arrayUnion([targetUserId]),
      'moderators': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> removeAdmin(String roomId, String targetUserId) async {
    final currentUserId = _currentUserId;

    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) throw Exception('Room not found');
    final data = doc.data()!;
    final ownerId = data['ownerId'] as String? ?? data['hostId'] as String? ?? '';
    if (currentUserId != ownerId) throw Exception('Only the owner can remove admins');
    if (targetUserId == ownerId) throw Exception('Cannot remove the owner from admins');

    await _firestore.collection('rooms').doc(roomId).update({
      'admins': FieldValue.arrayRemove([targetUserId]),
      'moderators': FieldValue.arrayRemove([targetUserId]),
    });
  }

  Future<void> updateRoomName(String roomId, String newName) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) throw Exception('Room name cannot be empty');
    if (trimmedName.length > 100) throw Exception('Room name cannot exceed 100 characters');

    await _firestore.collection('rooms').doc(roomId).update({
      'title': trimmedName,
      'name': trimmedName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRoomHeader(String roomId, String newHeader) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);
    final trimmedHeader = newHeader.trim();
    if (trimmedHeader.isEmpty) throw Exception('Room header cannot be empty');
    if (trimmedHeader.length > 100) throw Exception('Room header cannot exceed 100 characters');

    await _firestore.collection('rooms').doc(roomId).update({
      'header': trimmedHeader,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> lockRoom(String roomId) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);

    await _firestore.collection('rooms').doc(roomId).update({
      'isLocked': true,
      'isRoomLocked': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unlockRoom(String roomId) async {
    final currentUserId = _currentUserId;
    await _assertAdminOrOwner(roomId, currentUserId);

    await _firestore.collection('rooms').doc(roomId).update({
      'isLocked': false,
      'isRoomLocked': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('No authenticated user');
    return uid;
  }
}

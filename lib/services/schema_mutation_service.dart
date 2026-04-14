import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/schema_migration_flags.dart';
import '../core/telemetry/app_telemetry.dart';
import '../features/friends/models/friendship_model.dart';
import '../models/adult_profile_model.dart';
import '../models/profile_privacy_model.dart';

class SchemaMutationService {
  SchemaMutationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Set<String> _identityFields = <String>{
    'username',
    'usernameLower',
    'email',
  };

  static const Set<String> _profilePublicFields = <String>{
    'avatarUrl',
    'coverPhotoUrl',
    'galleryUrls',
    'introVideoUrl',
    'bio',
    'aboutMe',
    'age',
    'gender',
    'location',
    'relationshipStatus',
    'vibePrompt',
    'firstDatePrompt',
    'musicTastePrompt',
    'interests',
    'isPrivate',
  };

  static const Set<String> _preferencesFields = <String>{
    'themeId',
    'camViewPolicy',
    'profileAccentColor',
    'profileBgGradientStart',
    'profileBgGradientEnd',
    'profileMusicUrl',
    'profileMusicTitle',
  };

  static const Set<String> _verificationFields = <String>{
    'adultModeEnabled',
    'adultConsentAccepted',
  };

  static const Set<String> _knownProfileWriteFields = <String>{
    ..._identityFields,
    ..._profilePublicFields,
    ..._preferencesFields,
    ..._verificationFields,
  };

  Future<void> createUserProfile({
    required User user,
    bool? mirrorLegacyAvatarInUsers,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final profilePublicRef = _firestore
        .collection('profile_public')
        .doc(user.uid);

    final userSnapshot = await userRef.get();
    final now = FieldValue.serverTimestamp();

    final identityPayload = <String, dynamic>{
      'username': user.displayName ?? '',
      'usernameLower': (user.displayName ?? '').toLowerCase(),
      'email': user.email ?? '',
      'updatedAt': now,
    };

    if (mirrorLegacyAvatarInUsers ??
        SchemaMigrationFlags.enableAvatarLegacyWrite) {
      identityPayload['avatarUrl'] = user.photoURL;
      _logEnforcementEvent(
        action: 'legacy_avatar_mirror_write',
        userId: user.uid,
        metadata: <String, Object?>{'target': 'users.avatarUrl'},
      );
    }

    await userRef.set({
      ...identityPayload,
      if (!userSnapshot.exists) 'id': user.uid,
      if (!userSnapshot.exists) 'createdAt': now,
    }, SetOptions(merge: true));

    await profilePublicRef.set({
      'userId': user.uid,
      'avatarUrl': user.photoURL,
      'updatedAt': now,
      if (!(await profilePublicRef.get()).exists) 'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> updateProfilePublic({
    required String userId,
    required Map<String, dynamic> userData,
    required ProfilePrivacyModel privacy,
    required AdultProfileModel adultProfile,
    bool? mirrorLegacyUserDoc,
  }) async {
    final usersRef = _firestore.collection('users').doc(userId);
    final profilePublicRef = _firestore
        .collection('profile_public')
        .doc(userId);
    final preferencesRef = _firestore.collection('preferences').doc(userId);
    final verificationRef = _firestore.collection('verification').doc(userId);
    final privacyRef = usersRef.collection('privacy').doc('settings');
    final adultRef = usersRef.collection('adult_profile').doc('details');

    final now = FieldValue.serverTimestamp();

    _validateKnownProfileFields(userData: userData, userId: userId);

    final identityPayload = _pickAllowedFields(
      userData: userData,
      allowedFields: _identityFields,
    )..['updatedAt'] = now;

    final profilePublicPayload = _pickAllowedFields(
      userData: userData,
      allowedFields: _profilePublicFields,
    )..addAll(<String, dynamic>{'userId': userId, 'updatedAt': now});

    profilePublicPayload['galleryUrls'] =
        userData['galleryUrls'] ?? const <dynamic>[];
    profilePublicPayload['interests'] =
        userData['interests'] ?? const <dynamic>[];

    final preferencesPayload = _pickAllowedFields(
      userData: userData,
      allowedFields: _preferencesFields,
    )..addAll(<String, dynamic>{'userId': userId, 'updatedAt': now});

    final verificationPayload = _pickAllowedFields(
      userData: userData,
      allowedFields: _verificationFields,
    )..addAll(<String, dynamic>{'userId': userId, 'updatedAt': now});

    final batch = _firestore.batch();

    batch.set(usersRef, identityPayload, SetOptions(merge: true));
    batch.set(profilePublicRef, profilePublicPayload, SetOptions(merge: true));
    batch.set(preferencesRef, preferencesPayload, SetOptions(merge: true));
    batch.set(verificationRef, verificationPayload, SetOptions(merge: true));

    // Preserve existing runtime paths while migration is in progress.
    batch.set(privacyRef, {
      ...privacy.toJson(),
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(adultRef, {
      ...adultProfile.toJson(),
      'updatedAt': now,
    }, SetOptions(merge: true));

    if (mirrorLegacyUserDoc ?? SchemaMigrationFlags.enableProfileLegacyWrite) {
      batch.set(usersRef, {
        ...userData,
        'updatedAt': now,
      }, SetOptions(merge: true));
      _logEnforcementEvent(
        action: 'legacy_profile_mirror_write',
        userId: userId,
        metadata: <String, Object?>{'target': 'users/*'},
      );
    }

    await batch.commit();
  }

  Future<void> setVerificationStatus({
    required String userId,
    required bool isVerified,
    String? verifiedBy,
    bool? mirrorLegacyUsersDoc,
  }) async {
    final verificationRef = _firestore.collection('verification').doc(userId);
    final usersRef = _firestore.collection('users').doc(userId);

    final now = FieldValue.serverTimestamp();
    await verificationRef.set({
      'userId': userId,
      'isVerified': isVerified,
      'verifiedAt': isVerified ? now : FieldValue.delete(),
      'verifiedBy': isVerified ? verifiedBy : FieldValue.delete(),
      'updatedAt': now,
    }, SetOptions(merge: true));

    if (mirrorLegacyUsersDoc ?? SchemaMigrationFlags.enableProfileLegacyWrite) {
      await usersRef.set({
        'isVerified': isVerified,
        'verifiedAt': isVerified ? now : FieldValue.delete(),
        'verifiedBy': isVerified ? verifiedBy : FieldValue.delete(),
      }, SetOptions(merge: true));
      _logEnforcementEvent(
        action: 'legacy_verification_mirror_write',
        userId: userId,
        metadata: <String, Object?>{'target': 'users.isVerified'},
      );
    }
  }

  Future<void> setLegacyFavoriteFriend({
    required String userId,
    required String friendId,
    required bool isFavorite,
  }) async {
    if (!SchemaMigrationFlags.enableFriendLegacyWrite) {
      _logEnforcementEvent(
        action: 'legacy_friend_write_blocked',
        userId: userId,
        result: 'disabled',
        metadata: <String, Object?>{'friendId': friendId},
      );
      return;
    }

    await _firestore.collection('users').doc(userId).set({
      'favoriteFriendIds': isFavorite
          ? FieldValue.arrayUnion(<String>[friendId])
          : FieldValue.arrayRemove(<String>[friendId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _logEnforcementEvent(
      action: 'legacy_friend_write',
      userId: userId,
      metadata: <String, Object?>{
        'friendId': friendId,
        'isFavorite': isFavorite,
        'target': 'users.favoriteFriendIds',
      },
    );
  }

  Future<void> syncFriendLinks({
    required String firstUserId,
    required String secondUserId,
    required String status,
    required String requestedBy,
    String collectionName = 'friendships',
  }) async {
    if (status != 'pending' && status != 'accepted' && status != 'blocked') {
      throw StateError('Invalid friend link status: $status');
    }

    final sortedPair = FriendshipModel.sortedPair(firstUserId, secondUserId);
    final linkId = FriendshipModel.canonicalIdFor(firstUserId, secondUserId);
    final normalizedCollectionName = collectionName.trim().isEmpty
        ? 'friendships'
        : collectionName.trim();
    final now = FieldValue.serverTimestamp();

    final schemaPayload = <String, dynamic>{
      'users': <String>[sortedPair.userA, sortedPair.userB],
      'status': status,
      'requestedBy': requestedBy,
      if (status == 'pending') 'createdAt': now,
      'updatedAt': now,
    };

    final legacyPayload = <String, dynamic>{
      'userA': sortedPair.userA,
      'userB': sortedPair.userB,
      'status': status,
      'requestedBy': requestedBy,
      if (status == 'pending') 'createdAt': now,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('friend_links').doc(linkId),
      schemaPayload,
      SetOptions(merge: true),
    );

    if (SchemaMigrationFlags.enableFriendLegacyWrite ||
        normalizedCollectionName != 'friend_links') {
      batch.set(
        _firestore.collection(normalizedCollectionName).doc(linkId),
        legacyPayload,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Map<String, dynamic> _pickAllowedFields({
    required Map<String, dynamic> userData,
    required Set<String> allowedFields,
  }) {
    final payload = <String, dynamic>{};

    for (final entry in userData.entries) {
      if (allowedFields.contains(entry.key)) {
        payload[entry.key] = entry.value;
      }
    }

    return payload;
  }

  void _validateKnownProfileFields({
    required Map<String, dynamic> userData,
    required String userId,
  }) {
    final unknownKeys = userData.keys
        .where((key) => !_knownProfileWriteFields.contains(key))
        .toList(growable: false);

    if (unknownKeys.isEmpty) {
      return;
    }

    final message =
        'SchemaMutationService blocked unknown profile keys user=$userId keys=$unknownKeys';

    _logEnforcementEvent(
      level: SchemaMigrationFlags.strictWriteAuthority ? 'error' : 'warning',
      action: 'blocked_unknown_profile_keys',
      userId: userId,
      result: SchemaMigrationFlags.strictWriteAuthority
          ? 'blocked'
          : 'quarantined',
      metadata: <String, Object?>{'keys': unknownKeys.join(',')},
    );

    if (SchemaMigrationFlags.strictWriteAuthority) {
      throw StateError(message);
    }

    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // ── Messages / Conversations domain ───────────────────────────────────────

  /// Creates or opens a direct conversation between [initiatorId] and [recipientId].
  /// Returns the canonical conversation document ID.
  ///
  /// Write path: conversations/{canonicalId}
  /// Forbidden: writing user identity fields, wallet fields, or verification fields.
  Future<String> createDirectConversation({
    required String initiatorId,
    required String recipientId,
    Map<String, String> participantNames = const <String, String>{},
  }) async {
    final sortedIds = ([initiatorId.trim(), recipientId.trim()]..sort());
    final conversationId = '${sortedIds[0]}_${sortedIds[1]}';
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final now = FieldValue.serverTimestamp();

    await convRef.set(<String, dynamic>{
      'participantIds': sortedIds,
      'participantNames': participantNames,
      'type': 'direct',
      'status': 'active',
      'isArchived': false,
      'pinnedBy': <String>[],
      'lastReadAt': <String, dynamic>{},
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    _logEnforcementEvent(
      action: 'messages_conversation_created',
      userId: initiatorId,
      metadata: <String, Object?>{
        'conversationId': conversationId,
        'recipient': recipientId,
      },
    );

    return conversationId;
  }

  /// Sends a message to an existing conversation.
  ///
  /// Write paths:
  ///   conversations/{conversationId}/messages/{messageId}
  ///   conversations/{conversationId} — updates lastMessage* fields only.
  ///
  /// Forbidden: any field outside [_messageEntryFields] or [_conversationsFields].
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    _validateMessageText(text: text, userId: senderId);

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    final msgPayload = <String, dynamic>{
      'senderId': senderId,
      'text': text.trim(),
      'sentAt': now,
      'type': messageType,
      'readBy': <String>[senderId],
      if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
    };

    final convUpdate = <String, dynamic>{
      'lastMessageAt': now,
      'lastMessagePreview': text.trim().length > 120
          ? '${text.trim().substring(0, 120)}…'
          : text.trim(),
      'lastMessageSenderId': senderId,
      'lastMessageId': msgRef.id,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(msgRef, msgPayload);
    batch.set(convRef, convUpdate, SetOptions(merge: true));
    await batch.commit();

    _logEnforcementEvent(
      action: 'messages_message_sent',
      userId: senderId,
      metadata: <String, Object?>{
        'conversationId': conversationId,
        'messageId': msgRef.id,
        'messageType': messageType,
      },
    );
  }

  /// Marks all messages up to [upToTime] as read for [userId] in [conversationId].
  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.set(<String, dynamic>{
      'lastReadAt': <String, dynamic>{userId: FieldValue.serverTimestamp()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _validateMessageText({required String text, required String userId}) {
    if (text.trim().isEmpty) {
      _logEnforcementEvent(
        level: 'warning',
        action: 'messages_empty_text_blocked',
        userId: userId,
        result: 'blocked',
      );
      throw StateError(
        'SchemaMutationService: message text must not be empty.',
      );
    }
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  void _logEnforcementEvent({
    String level = 'info',
    required String action,
    required String userId,
    String? result,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    AppTelemetry.logEnforcementEvent(
      level: level,
      action: action,
      message: 'Schema mutation enforcement event.',
      userId: userId,
      result: result,
      metadata: metadata,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mixvy/models/message_model.dart';
import 'package:mixvy/models/room_participant_model.dart';
import 'presence_provider.dart';
import 'room_meta_state_provider.dart';
import 'room_participants_state_provider.dart';
import 'room_activity_state_provider.dart';
import 'room_message_preview_state_provider.dart';

abstract class RoomStateContract {
  String get title;
  List<MessageModel> get messages;
  Map<String, bool> get typingUsers;
}

class RoomLiveState implements RoomStateContract {
  @override
  final String title;
  @override
  final List<MessageModel> messages;
  @override
  final Map<String, bool> typingUsers;

  final Map<String, dynamic> roomDoc;
  final List<RoomParticipantModel> participants;
  final List<RoomPresenceModel> presence;

  RoomLiveState({
    required this.title,
    required this.messages,
    required this.typingUsers,
    required this.roomDoc,
    required this.participants,
    required this.presence,
  });
}

class RoomSchemaValidator {
  static void validate(Map<String, dynamic>? roomDoc) {
    if (roomDoc == null || roomDoc.isEmpty) {
      throw ArgumentError('Room document is null or empty');
    }

    if (!roomDoc.containsKey('meta')) {
      throw ArgumentError('Room document is missing required key: meta');
    }

    final meta = roomDoc['meta'];
    if (meta is! Map<String, dynamic>) {
      throw ArgumentError('Room meta is not a valid map');
    }

    if (!meta.containsKey('title')) {
      throw ArgumentError('Room meta is missing required key: title');
    }
  }
}

class RoomLiveStateMapper {
  static RoomLiveState fromFirestore({
    required Map<String, dynamic>? roomDoc,
    required List<RoomParticipantModel> participants,
    required List<RoomPresenceModel> presence,
    required List<MessageModel> messagePreview,
    required Map<String, bool> typing,
  }) {
    // Validate the raw Firestore document
    RoomSchemaValidator.validate(roomDoc);

    // Normalize fields to ensure no nulls or missing keys
    final normalizedRoomDoc = roomDoc ?? {};
    final normalizedMeta = normalizedRoomDoc['meta'] ?? {};

    final String title = (normalizedMeta['title'] as String?) ?? '';
    final List<MessageModel> messages = messagePreview;
    final Map<String, bool> typingUsers = typing;

    // Validate the structure
    assert(title.isNotEmpty, 'Room title must not be empty');

    debugPrint('RoomLiveState VALIDATED OK');

    return RoomLiveState(
      title: title,
      messages: messages,
      typingUsers: typingUsers,
      roomDoc: normalizedRoomDoc,
      participants: participants,
      presence: presence,
    );
  }
}

final roomLiveStateProvider = StreamProvider.autoDispose.family<RoomLiveState, String>((ref, roomId) {
  final metaStream = ref.watch(roomMetaStateProvider(roomId).stream);
  final participantsStream = ref.watch(roomParticipantsStateProvider(roomId).stream);
  final activityStream = ref.watch(roomActivityStateProvider(roomId).stream);
  final messagePreviewStream = ref.watch(roomMessagePreviewStateProvider(roomId).stream);

  return Rx.combineLatest4(
    metaStream,
    participantsStream,
    activityStream,
    messagePreviewStream,
    (RoomMetaState meta, RoomParticipantsState participants, RoomActivityState activity, RoomMessagePreviewState messagePreview) {
      return RoomLiveStateMapper.fromFirestore(
        roomDoc: meta.roomDoc,
        participants: participants.participants,
        presence: activity.presence,
        messagePreview: messagePreview.messagePreview,
        typing: activity.typing,
      );
    },
  );
});

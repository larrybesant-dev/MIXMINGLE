import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'participant_providers.dart';
import 'message_providers.dart';
import 'presence_provider.dart';
import 'room_policy_provider.dart';
import 'host_provider.dart';
import '../../features/feed/providers/typing_providers.dart';
import 'package:rxdart/rxdart.dart';
import 'room_meta_state_provider.dart';
import 'room_participants_state_provider.dart';
import 'room_activity_state_provider.dart';
import 'room_message_preview_state_provider.dart';

class RoomLiveState {
  final Map<String, dynamic>? roomDoc;
  final List<RoomParticipantModel> participants;
  final List<RoomPresenceModel> presence;
  final List<MessageModel> messagePreview;
  final Map<String, bool> typing;

  RoomLiveState({
    required this.roomDoc,
    required this.participants,
    required this.presence,
    required this.messagePreview,
    required this.typing,
  });
}

final roomLiveStateProvider = StreamProvider.family<RoomLiveState, String>((ref, roomId) {
  final metaSlice = ref.watch(roomMetaStateProvider(roomId));
  final participantsSlice = ref.watch(roomParticipantsStateProvider(roomId));
  final activitySlice = ref.watch(roomActivityStateProvider(roomId));
  final messagePreviewSlice = ref.watch(roomMessagePreviewStateProvider(roomId));

  return Rx.combineLatest4(
    metaSlice.stream,
    participantsSlice.stream,
    activitySlice.stream,
    messagePreviewSlice.stream,
    (RoomMetaState meta, RoomParticipantsState participants, RoomActivityState activity, RoomMessagePreviewState messagePreview) => RoomLiveState(
      roomDoc: meta.roomDoc,
      participants: participants.participants,
      presence: activity.presence,
      messagePreview: messagePreview.messagePreview,
      typing: activity.typing,
    ),
  );
});

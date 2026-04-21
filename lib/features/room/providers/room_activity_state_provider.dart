import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/feed/providers/typing_providers.dart';
import 'presence_provider.dart';
import '../../models/presence_model.dart';
import '../contracts/room_activity_contract.dart';

class RoomActivityState {
  final List<RoomPresenceModel> presence;
  final Map<String, bool> typing;
  RoomActivityState({required this.presence, required this.typing});
}

final roomActivityStateProvider = StreamProvider.family<RoomActivityState, String>((ref, roomId) async* {
  List<RoomPresenceModel>? previousPresence;
  Map<String, bool>? previousTyping;
  final presenceStream = ref.watch(roomPresenceStreamProvider(roomId).stream);
  final typingStream = ref.watch(typingStreamProvider(roomId).stream);
  await for (final values in Rx.combineLatest2(
    presenceStream,
    typingStream,
    (presence, typing) => [presence, typing],
  )) {
    final presence = values[0] as List<RoomPresenceModel>;
    final typing = values[1] as Map<String, bool>;
    if (previousPresence != null && previousTyping != null &&
        !RoomActivityContract.shouldRebuild(previousPresence, presence, previousTyping, typing)) {
      continue;
    }
    previousPresence = presence;
    previousTyping = typing;
    yield RoomActivityState(presence: presence, typing: typing);
  }
});

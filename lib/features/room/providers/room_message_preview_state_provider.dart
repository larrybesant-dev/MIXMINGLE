import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'message_providers.dart';
import 'package:mixvy/models/message_model.dart';
import '../contracts/room_message_preview_contract.dart';

class RoomMessagePreviewState {
  final List<MessageModel> messagePreview;
  RoomMessagePreviewState({required this.messagePreview});
}

final roomMessagePreviewStateProvider = StreamProvider.autoDispose.family<RoomMessagePreviewState, String>((ref, roomId) async* {
  List<MessageModel>? previous;
  await for (final messages in ref.watch(messageStreamProvider(roomId).stream)) {
    if (previous != null && !RoomMessagePreviewContract.shouldRebuild(previous, messages)) {
      continue;
    }
    previous = messages;
    yield RoomMessagePreviewState(messagePreview: messages);
  }
});

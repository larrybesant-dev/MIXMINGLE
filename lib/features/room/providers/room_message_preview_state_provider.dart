import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'MessageModel_providers.dart';
import 'package:mixvy/features/messaging/models/message_model.dart';
import '../contracts/room_MessageModel_preview_contract.dart';

class RoomMessageModelPreviewState {
  final List<MessageModel> MessageModelPreview;
  RoomMessageModelPreviewState({required this.MessageModelPreview});
}

final roomMessageModelPreviewStateProvider = StreamProvider.autoDispose.family<RoomMessageModelPreviewState, String>((ref, roomId) async* {
  List<MessageModel>? previous;
  // ignore: deprecated_member_use
  await for (final MessageModel in ref.watch(MessageModeltreamProvider(roomId).stream)) {
    if (previous != null && !RoomMessageModelPreviewContract.shouldRebuild(previous, MessageModel)) {
      continue;
    }
    previous = MessageModel;
    yield RoomMessageModelPreviewState(MessageModelPreview: MessageModel);
  }
});

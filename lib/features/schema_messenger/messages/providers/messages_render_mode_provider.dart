import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessagesPaneRenderMode {
  legacy,
  schema,
  dual,
}

class MessagesPaneRenderModeController extends Notifier<MessagesPaneRenderMode> {
  @override
  MessagesPaneRenderMode build() => MessagesPaneRenderMode.legacy;

  void setMode(MessagesPaneRenderMode mode) {
    state = mode;
  }
}

final messagesPaneRenderModeProvider =
    NotifierProvider<MessagesPaneRenderModeController, MessagesPaneRenderMode>(
  MessagesPaneRenderModeController.new,
);

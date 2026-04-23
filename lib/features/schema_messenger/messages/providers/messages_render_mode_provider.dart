import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessageModelPaneRenderMode {
  legacy,
  schema,
  dual,
}

class MessageModelPaneRenderModeController extends Notifier<MessageModelPaneRenderMode> {
  @override
  MessageModelPaneRenderMode build() => MessageModelPaneRenderMode.legacy;

  void setMode(MessageModelPaneRenderMode mode) {
    state = mode;
  }
}

final MessageModelPaneRenderModeProvider =
    NotifierProvider<MessageModelPaneRenderModeController, MessageModelPaneRenderMode>(
  MessageModelPaneRenderModeController.new,
);

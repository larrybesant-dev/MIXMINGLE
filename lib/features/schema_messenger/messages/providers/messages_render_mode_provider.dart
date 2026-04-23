import 'package:flutter_riverpod/flutter_riverpod.dart';

enum messagePaneRenderMode {
  legacy,
  schema,
  dual,
}

class messagePaneRenderModeController extends Notifier<messagePaneRenderMode> {
  @override
  messagePaneRenderMode build() => messagePaneRenderMode.legacy;

  void setMode(messagePaneRenderMode mode) {
    state = mode;
  }
}

final messagePaneRenderModeProvider =
    NotifierProvider<messagePaneRenderModeController, messagePaneRenderMode>(
  messagePaneRenderModeController.new,
);

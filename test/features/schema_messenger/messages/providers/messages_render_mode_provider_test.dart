import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/schema_messenger/MessageModel/providers/MessageModel_render_mode_provider.dart';

void main() {
  test('MessageModel view defaults to legacy mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mode = container.read(MessageModelPaneRenderModeProvider);

    expect(mode, MessageModelPaneRenderMode.legacy);
  });
}

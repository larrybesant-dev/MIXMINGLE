import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_layout.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../core/theme.dart';
import '../../features/schema_messenger/friends/views/friends_schema_bridge_view.dart';
import '../../features/schema_messenger/messages/views/messages_schema_bridge_view.dart';
import '../../features/messaging/panes/chat_pane_view.dart';
import '../../features/messaging/panes/messages_pane_view.dart';
import '../../features/messaging/screens/new_message_screen.dart';
import 'desktop_messenger_shell.dart';

enum MessengerRouteKind { inbox, compose, conversation, friends }

class MessengerRouteState {
  const MessengerRouteState._({required this.kind, this.conversationId});

  final MessengerRouteKind kind;
  final String? conversationId;

  static String _routePath(GoRouterState state) => state.uri.path;

  static bool matches(GoRouterState state) {
    final path = _routePath(state);
    return path == '/messages' ||
        path == '/messages/new' ||
        path == '/friends' ||
        (path.startsWith('/messages/') && path.length > '/messages/'.length);
  }

  static MessengerRouteState fromGoRouterState(GoRouterState state) {
    final path = _routePath(state);

    if (path == '/messages') {
      return const MessengerRouteState._(kind: MessengerRouteKind.inbox);
    }
    if (path == '/messages/new') {
      return const MessengerRouteState._(kind: MessengerRouteKind.compose);
    }
    if (path == '/friends') {
      return const MessengerRouteState._(kind: MessengerRouteKind.friends);
    }
    if (path.startsWith('/messages/') && path.length > '/messages/'.length) {
      final conversationId = state.pathParameters['conversationId'];
      return MessengerRouteState._(
        kind: MessengerRouteKind.conversation,
        conversationId: conversationId,
      );
    }

    throw ArgumentError('Unsupported messenger route: $path');
  }
}

class MessengerShellRouteView extends ConsumerWidget {
  const MessengerShellRouteView({
    required this.routeState,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.child,
    super.key,
  });

  final MessengerRouteState routeState;
  final String userId;
  final String username;
  final String? avatarUrl;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isExpandedLayout) {
      return DesktopMessengerShell(
        routeState: routeState,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
      );
    }

    return switch (routeState.kind) {
      MessengerRouteKind.inbox => _MobileInboxRoute(
        userId: userId,
        child: child,
      ),
      MessengerRouteKind.compose => AppPageScaffold(
        appBar: AppBar(title: const Text('New Message')),
        body: child,
      ),
      MessengerRouteKind.conversation => AppPageScaffold(
        appBar: AppBar(title: Text(username)),
        body: child,
      ),
      MessengerRouteKind.friends => AppPageScaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: child,
      ),
    };
  }
}

class _MobileInboxRoute extends ConsumerWidget {
  const _MobileInboxRoute({required this.userId, required this.child});

  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsStreamProvider(userId));

    return AppPageScaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New message',
            onPressed: () => GoRouter.of(context).push('/messages/new'),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Message requests',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: VelvetNoir.surface,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => MessageRequestsSheet(
                  requestsAsync: requestsAsync,
                  userId: userId,
                ),
              );
            },
          ),
        ],
      ),
      body: child,
    );
  }
}

Widget buildMessengerRouteChild({
  required MessengerRouteState routeState,
  required String userId,
  required String username,
  required String? avatarUrl,
}) {
  switch (routeState.kind) {
    case MessengerRouteKind.inbox:
      return MessagesSchemaBridgeView(userId: userId, username: username);
    case MessengerRouteKind.compose:
      return NewMessagePaneView(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        showHeader: false,
      );
    case MessengerRouteKind.conversation:
      final conversationId = routeState.conversationId;
      if (conversationId == null || conversationId.isEmpty) {
        return const SizedBox.shrink();
      }
      return ChatPaneView(
        conversationId: conversationId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        showHeader: false,
      );
    case MessengerRouteKind.friends:
      return const FriendsSchemaBridgeView();
  }
}

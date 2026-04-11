import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_layout.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../core/theme.dart';
import '../../features/friends/panes/friends_pane_view.dart';
import '../../features/messaging/panes/chat_pane_view.dart';
import '../../features/messaging/panes/messages_pane_view.dart';
import '../../features/messaging/screens/new_message_screen.dart';
import 'desktop_messenger_shell.dart';

enum MessengerRouteKind {
  inbox,
  compose,
  conversation,
  friends,
}

class MessengerRouteState {
  const MessengerRouteState._({
    required this.kind,
    this.conversationId,
  });

  final MessengerRouteKind kind;
  final String? conversationId;

  static bool matches(GoRouterState state) {
    switch (state.matchedLocation) {
      case '/messages':
      case '/messages/new':
      case '/messages/:conversationId':
      case '/friends':
        return true;
      default:
        return false;
    }
  }

  static MessengerRouteState fromGoRouterState(GoRouterState state) {
    switch (state.matchedLocation) {
      case '/messages':
        return const MessengerRouteState._(kind: MessengerRouteKind.inbox);
      case '/messages/new':
        return const MessengerRouteState._(kind: MessengerRouteKind.compose);
      case '/messages/:conversationId':
        final conversationId = state.pathParameters['conversationId'];
        return MessengerRouteState._(
          kind: MessengerRouteKind.conversation,
          conversationId: conversationId,
        );
      case '/friends':
        return const MessengerRouteState._(kind: MessengerRouteKind.friends);
      default:
        throw ArgumentError('Unsupported messenger route: ${state.matchedLocation}');
    }
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
  const _MobileInboxRoute({
    required this.userId,
    required this.child,
  });

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
      return MessagesPaneView(
        userId: userId,
        username: username,
        showHeader: false,
      );
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
      return const FriendsPaneView(showHeader: false);
  }
}
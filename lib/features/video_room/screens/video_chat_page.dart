// Video Chat Main Page - Responsive layout with video grid, sidebars, and chat

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/chat_box_widget.dart';
import '../../../shared/widgets/top_bar_widget.dart';
import '../../../shared/widgets/notification_widget.dart';
import '../../../shared/widgets/friends_sidebar_widget.dart';
import '../../../shared/widgets/groups_sidebar_widget.dart';
import '../../../shared/widgets/video_grid_widget.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/providers/ui_provider.dart';
import '../../../shared/providers/notification_provider.dart';

/// Main video chat page
class VideoChatPage extends ConsumerWidget {
  const VideoChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final friendsSidebarCollapsed = ref.watch(friendsSidebarCollapsedProvider);
    final groupsSidebarCollapsed = ref.watch(groupsSidebarCollapsedProvider);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: DesignColors.surfaceDefault,
      body: Column(
        children: [
          // Top Navigation Bar
          TopBarWidget(
            onToggleDarkMode: () {
              // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
              ref.read(darkModeProvider.notifier).state = !darkMode;
            },
          ),
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Friends Sidebar
                if (!friendsSidebarCollapsed)
                  FriendsSidebarWidget(
                    onCollapse: () {
                      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                      ref.read(friendsSidebarCollapsedProvider.notifier).state =
                          true;
                    },
                  ),
                // Center Area: Video Grid + Chat
                Expanded(
                  child: Column(
                    children: [
                      // Video Grid (resizable)
                      Expanded(
                        flex: 3,
                        child: VideoGridWidget(
                          onExpandChat: () {
                            // Can add logic to expand chat
                          },
                        ),
                      ),
                      // Chat Box
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: DesignColors.accent,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const ChatBoxWidget(),
                      ),
                    ],
                  ),
                ),
                // Groups Sidebar
                if (!groupsSidebarCollapsed)
                  GroupsSidebarWidget(
                    onCollapse: () {
                      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                      ref.read(groupsSidebarCollapsedProvider.notifier).state =
                          true;
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      // Floating notifications
      floatingActionButton: notifications.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: notifications.take(3).map((notification) {
                return NotificationWidget(notification: notification);
              }).toList(),
            )
          : null,
    );
  }
}
